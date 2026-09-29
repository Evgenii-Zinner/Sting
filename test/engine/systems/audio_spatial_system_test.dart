import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/audio_emitter.dart';
import 'package:sting/engine/components/audio_listener.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/systems/audio_spatial_system.dart';

class MockAudioManager implements AudioManager {
  final Map<int, double> volumes = {};
  final Map<int, double> pans = {};

  @override
  void setVolume(int soundId, double volume) {
    volumes[soundId] = volume;
  }

  @override
  void setPan(int soundId, double pan) {
    pans[soundId] = pan;
  }
}

void main() {
  group('AudioEmitter Component', () {
    test('initializes and updates fields correctly', () {
      final emitter = AudioEmitter.create(
        soundId: 42,
        maxDistance: 500.0,
        referenceDistance: 50.0,
        volume: 0.8,
        rolloffFactor: 2.0,
        isLooping: true,
        isPlaying: false,
      );

      expect(emitter.soundId, 42);
      expect(emitter.maxDistance, 500.0);
      expect(emitter.referenceDistance, 50.0);
      expect(emitter.volume, closeTo(0.8, 0.001));
      expect(emitter.rolloffFactor, 2.0);
      expect(emitter.isLooping, isTrue);
      expect(emitter.isPlaying, isFalse);

      emitter.soundId = 10;
      emitter.volume = 0.5;
      emitter.isPlaying = true;

      expect(emitter.soundId, 10);
      expect(emitter.volume, closeTo(0.5, 0.001));
      expect(emitter.isPlaying, isTrue);
    });
  });

  group('AudioListener Component', () {
    test('initializes and updates fields correctly', () {
      final listener = AudioListener.create(
        hearingRange: 2000.0,
        masterVolume: 0.5,
      );

      expect(listener.hearingRange, 2000.0);
      expect(listener.masterVolume, closeTo(0.5, 0.001));

      listener.hearingRange = 1000.0;
      listener.masterVolume = 1.0;

      expect(listener.hearingRange, 1000.0);
      expect(listener.masterVolume, closeTo(1.0, 0.001));
    });
  });

  group('AudioSpatialSystem', () {
    late ComponentStorage<Position> positionCaste;
    late ComponentStorage<AudioListener> listenerCaste;
    late ComponentStorage<AudioEmitter> emitterCaste;
    late Query2<Position, AudioListener> listenerQuery;
    late Query2<Position, AudioEmitter> emitterQuery;
    late MockAudioManager audioManager;
    late AudioSpatialSystem system;

    setUp(() {
      positionCaste = ComponentStorage<Position>(10);
      listenerCaste = ComponentStorage<AudioListener>(10);
      emitterCaste = ComponentStorage<AudioEmitter>(10);

      listenerQuery = Query2(positionCaste, listenerCaste);
      emitterQuery = Query2(positionCaste, emitterCaste);

      audioManager = MockAudioManager();

      system = AudioSpatialSystem(
        audioManager: audioManager,
        listenerQuery: listenerQuery,
        emitterQuery: emitterQuery,
      );
    });

    test('updates volumes and pans correctly based on distance and listener', () {
      // Add listener at origin
      final listenerEntity = 1;
      positionCaste.add(listenerEntity, Position.create(0.0, 0.0));
      listenerCaste.add(listenerEntity, AudioListener.create(masterVolume: 1.0, hearingRange: 1000.0));

      // Add emitter 1 exactly at reference distance (should be full volume, pan 0)
      final emitter1 = 2;
      positionCaste.add(emitter1, Position.create(0.0, -100.0));
      emitterCaste.add(emitter1, AudioEmitter.create(soundId: 101, referenceDistance: 100.0, maxDistance: 1000.0));

      // Add emitter 2 far away to the right (should have attenuated volume, pan > 0)
      final emitter2 = 3;
      positionCaste.add(emitter2, Position.create(500.0, 0.0));
      emitterCaste.add(emitter2, AudioEmitter.create(soundId: 102, referenceDistance: 100.0, rolloffFactor: 1.0, maxDistance: 1000.0));

      // Add emitter 3 far away to the left (should have attenuated volume, pan < 0)
      final emitter3 = 4;
      positionCaste.add(emitter3, Position.create(-500.0, 0.0));
      emitterCaste.add(emitter3, AudioEmitter.create(soundId: 103, referenceDistance: 100.0, rolloffFactor: 1.0, maxDistance: 1000.0));

      // Add emitter 4 out of max distance (volume 0)
      final emitter4 = 5;
      positionCaste.add(emitter4, Position.create(1500.0, 0.0));
      emitterCaste.add(emitter4, AudioEmitter.create(soundId: 104, referenceDistance: 100.0, maxDistance: 1000.0));

      system.update();

      // Check Emitter 1
      expect(audioManager.volumes[101], closeTo(1.0, 0.001));
      expect(audioManager.pans[101], closeTo(0.0, 0.001));

      // Check Emitter 2
      // distance = 500, ref = 100, rolloff = 1
      // attenuation = 100 / (100 + 1 * (500 - 100)) = 100 / 500 = 0.2
      expect(audioManager.volumes[102], closeTo(0.2, 0.001));
      expect(audioManager.pans[102], closeTo(500.0 / 1000.0, 0.001)); // 0.5

      // Check Emitter 3
      expect(audioManager.volumes[103], closeTo(0.2, 0.001));
      expect(audioManager.pans[103], closeTo(-500.0 / 1000.0, 0.001)); // -0.5

      // Check Emitter 4
      expect(audioManager.volumes[104], closeTo(0.0, 0.001));
    });

    test('respects listener master volume', () {
      final listenerEntity = 1;
      positionCaste.add(listenerEntity, Position.create(0.0, 0.0));
      listenerCaste.add(listenerEntity, AudioListener.create(masterVolume: 0.5, hearingRange: 1000.0));

      final emitterEntity = 2;
      positionCaste.add(emitterEntity, Position.create(0.0, 0.0));
      emitterCaste.add(emitterEntity, AudioEmitter.create(soundId: 200, volume: 1.0));

      system.update();

      expect(audioManager.volumes[200], closeTo(0.5, 0.001));
    });

    test('ignores non-playing emitters', () {
      final listenerEntity = 1;
      positionCaste.add(listenerEntity, Position.create(0.0, 0.0));
      listenerCaste.add(listenerEntity, AudioListener.create());

      final emitterEntity = 2;
      positionCaste.add(emitterEntity, Position.create(0.0, 0.0));
      emitterCaste.add(emitterEntity, AudioEmitter.create(soundId: 200, isPlaying: false));

      system.update();

      expect(audioManager.volumes.containsKey(200), isFalse);
    });

    test('does nothing if no listener is present', () {
      final emitterEntity = 2;
      positionCaste.add(emitterEntity, Position.create(0.0, 0.0));
      emitterCaste.add(emitterEntity, AudioEmitter.create(soundId: 200));

      system.update();

      expect(audioManager.volumes.containsKey(200), isFalse);
    });
  });
}
