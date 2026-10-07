import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/audio/audio_backend.dart';
import 'package:sting/engine/audio/pluggable_audio_manager.dart';

class MockAudioBackend implements AudioBackend {
  double lastVolume = -1.0;
  double lastPan = -2.0;
  int lastId = -1;

  @override
  Future<void> init() async {}

  @override
  Future<void> loadSound(int soundId, String path) async {}

  @override
  void unloadSound(int soundId) {}

  @override
  int play(
    int soundId, {
    double volume = 1.0,
    double pitch = 1.0,
    bool loop = false,
  }) {
    return 1;
  }

  @override
  void stop(int handle) {}

  @override
  void setVolume(int handleOrSoundId, double volume) {
    lastId = handleOrSoundId;
    lastVolume = volume;
  }

  @override
  void setPan(int handleOrSoundId, double pan) {
    lastId = handleOrSoundId;
    lastPan = pan;
  }

  @override
  void dispose() {}
}

void main() {
  group('PluggableAudioManager', () {
    test('defaults to NullAudioBackend', () {
      final manager = PluggableAudioManager();
      expect(manager.backend, isA<NullAudioBackend>());
    });

    test('accepts custom backend in constructor', () {
      final mockBackend = MockAudioBackend();
      final manager = PluggableAudioManager(backend: mockBackend);
      expect(manager.backend, mockBackend);
    });

    test('can swap backend at runtime', () {
      final manager = PluggableAudioManager();
      expect(manager.backend, isA<NullAudioBackend>());

      final mockBackend = MockAudioBackend();
      manager.setBackend(mockBackend);
      expect(manager.backend, mockBackend);
    });

    test('delegates setVolume to active backend', () {
      final mockBackend = MockAudioBackend();
      final manager = PluggableAudioManager(backend: mockBackend);

      manager.setVolume(42, 0.75);

      expect(mockBackend.lastId, 42);
      expect(mockBackend.lastVolume, 0.75);
    });

    test('delegates setPan to active backend', () {
      final mockBackend = MockAudioBackend();
      final manager = PluggableAudioManager(backend: mockBackend);

      manager.setPan(42, -0.5);

      expect(mockBackend.lastId, 42);
      expect(mockBackend.lastPan, -0.5);
    });
  });
}
