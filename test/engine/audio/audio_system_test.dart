import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/audio/audio_event_queue.dart';
import 'package:sting/engine/audio/audio_system.dart';

void main() {
  group('AudioSystem', () {
    test('processes queued events and calls bindings', () {
      final queue = AudioEventQueue(10);
      final system = AudioSystem(queue, maxActiveSounds: 10);

      queue.enqueue(1, 100, volume: 0.5, pitch: 1.5, loop: true);
      queue.enqueue(2, 101);

      expect(queue.length, 2);
      expect(system.activeSoundCount, 0);

      system.update();

      expect(queue.length, 0);
      expect(system.activeSoundCount, 2);

      // Playback handles will be positive integers assigned by AudioBindings.
      expect(system.getActiveHandle(0), greaterThan(0));
      expect(system.getActiveEntityId(0), 100);

      expect(system.getActiveHandle(1), greaterThan(system.getActiveHandle(0)));
      expect(system.getActiveEntityId(1), 101);
    });

    test('respects maxActiveSounds limit', () {
      final queue = AudioEventQueue(10);
      final system = AudioSystem(queue, maxActiveSounds: 2);

      queue.enqueue(1, 100);
      queue.enqueue(2, 101);
      queue.enqueue(3, 102);

      system.update();

      expect(system.activeSoundCount, 2);
      // Event 3 was discarded since maxActiveSounds is 2.
    });

    test('clearActiveSounds resets the count', () {
      final queue = AudioEventQueue(10);
      final system = AudioSystem(queue, maxActiveSounds: 10);

      queue.enqueue(1, 100);
      system.update();

      expect(system.activeSoundCount, 1);

      system.clearActiveSounds();
      expect(system.activeSoundCount, 0);
    });
  });
}
