import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/audio/audio_event_queue.dart';

void main() {
  group('AudioEventQueue', () {
    test('initializes with zero length', () {
      final queue = AudioEventQueue(10);
      expect(queue.length, equals(0));
    });

    test('enqueues and processes events sequentially', () {
      final queue = AudioEventQueue(10);

      expect(queue.enqueue(1, 100), isTrue);
      expect(queue.enqueue(2, 101), isTrue);
      expect(queue.length, equals(2));

      final results = <List<int>>[];
      queue.process((soundId, entityId) {
        results.add([soundId, entityId]);
      });

      expect(results.length, equals(2));
      expect(results[0], equals([1, 100]));
      expect(results[1], equals([2, 101]));

      // Should be empty after processing
      expect(queue.length, equals(0));
    });

    test('handles ring buffer wrapping correctly', () {
      final queue = AudioEventQueue(3);

      // Fill to capacity
      queue.enqueue(1, 100);
      queue.enqueue(2, 101);
      queue.enqueue(3, 102);
      expect(queue.length, equals(3));

      // Process 2 events
      final results1 = <List<int>>[];
      // We can't process partially with the current API which clears the queue
      queue.process((soundId, entityId) {
        results1.add([soundId, entityId]);
      });

      expect(results1.length, equals(3));
      expect(queue.length, equals(0));

      // Now enqueue more events to trigger wrap
      queue.enqueue(4, 103);
      queue.enqueue(5, 104);
      queue.enqueue(6, 105);

      final results2 = <List<int>>[];
      queue.process((soundId, entityId) {
        results2.add([soundId, entityId]);
      });

      expect(results2.length, equals(3));
      expect(results2[0], equals([4, 103]));
      expect(results2[1], equals([5, 104]));
      expect(results2[2], equals([6, 105]));
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
      queue.process((soundId, entityId) {
        processed = true;
      });

      expect(processed, isFalse);
      expect(queue.length, equals(0));
    });
  });
}
