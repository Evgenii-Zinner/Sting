import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/audio/audio_event_queue.dart';

void main() {
  group('AudioEventQueue', () {
    test('initializes with zero length', () {
      final queue = AudioEventQueue(10);
      expect(queue.length, equals(0));
    });

    test('enqueues and processes events sequentially with default params', () {
      final queue = AudioEventQueue(10);

      expect(queue.enqueue(1, 100), isTrue);
      expect(queue.enqueue(2, 101), isTrue);
      expect(queue.length, equals(2));

      final results = <List<dynamic>>[];
      queue.process((soundId, entityId, volume, pitch, loop) {
        results.add([soundId, entityId, volume, pitch, loop]);
      });

      expect(results.length, equals(2));
      expect(results[0], equals([1, 100, 1.0, 1.0, false]));
      expect(results[1], equals([2, 101, 1.0, 1.0, false]));

      // Should be empty after processing
      expect(queue.length, equals(0));
    });

    test('enqueues and processes events with custom params', () {
      final queue = AudioEventQueue(10);

      expect(
          queue.enqueue(1, 100, volume: 0.5, pitch: 1.2, loop: true), isTrue);
      expect(
          queue.enqueue(2, 101, volume: 2.0, pitch: 0.8, loop: false), isTrue);
      expect(queue.length, equals(2));

      final results = <List<dynamic>>[];
      queue.process((soundId, entityId, volume, pitch, loop) {
        results.add([soundId, entityId, volume, pitch, loop]);
      });

      expect(results.length, equals(2));
      expect(results[0], equals([1, 100, 0.5, 1.2, true]));
      expect(results[1], equals([2, 101, 2.0, 0.8, false]));
    });

    test('handles ring buffer wrapping correctly', () {
      final queue = AudioEventQueue(3);

      // Fill to capacity
      queue.enqueue(1, 100);
      queue.enqueue(2, 101);
      queue.enqueue(3, 102);
      expect(queue.length, equals(3));

      // Process 2 events
      final results1 = <List<dynamic>>[];
      // We can't process partially with the current API which clears the queue
      queue.process((soundId, entityId, volume, pitch, loop) {
        results1.add([soundId, entityId, volume, pitch, loop]);
      });

      expect(results1.length, equals(3));
      expect(queue.length, equals(0));

      // Now enqueue more events to trigger wrap
      queue.enqueue(4, 103);
      queue.enqueue(5, 104);
      queue.enqueue(6, 105);

      final results2 = <List<dynamic>>[];
      queue.process((soundId, entityId, volume, pitch, loop) {
        results2.add([soundId, entityId, volume, pitch, loop]);
      });

      expect(results2.length, equals(3));
      expect(results2[0][0], equals(4));
      expect(results2[0][1], equals(103));
      expect(results2[1][0], equals(5));
      expect(results2[1][1], equals(104));
      expect(results2[2][0], equals(6));
      expect(results2[2][1], equals(105));
    });

    test('returns false when enqueueing over capacity', () {
      final queue = AudioEventQueue(2);

      expect(queue.enqueue(1, 100), isTrue);
      expect(queue.enqueue(2, 101), isTrue);
      expect(queue.length, equals(2));

      expect(queue.enqueue(3, 102), isFalse);
      expect(queue.length, equals(2)); // Still 2
    });

    test('processes empty queue correctly', () {
      final queue = AudioEventQueue(5);

      bool processed = false;
      queue.process((soundId, entityId, volume, pitch, loop) {
        processed = true;
      });

      expect(processed, isFalse);
      expect(queue.length, equals(0));
    });
  });
}
