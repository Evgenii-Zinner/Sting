import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/movement_queue.dart';

void main() {
  group('MovementQueue Component Tests', () {
    test('Initialization sets capacity and defaults correctly', () {
      final queue = MovementQueue.create(5);

      expect(queue.capacity, 5);
      expect(queue.count, 0);
      expect(queue.head, 0);
      expect(queue.tail, 0);
      expect(queue.isEmpty, true);
      expect(queue.isFull, false);
      expect(queue.peek(), -1);
      expect(queue.dequeue(), -1);
    });

    test('Enqueue and Dequeue logic works', () {
      final queue = MovementQueue.create(3);

      queue.enqueue(10);
      expect(queue.count, 1);
      expect(queue.isEmpty, false);
      expect(queue.isFull, false);
      expect(queue.peek(), 10);

      queue.enqueue(20);
      expect(queue.count, 2);
      expect(queue.peek(), 10);

      expect(queue.dequeue(), 10);
      expect(queue.count, 1);
      expect(queue.peek(), 20);

      expect(queue.dequeue(), 20);
      expect(queue.count, 0);
      expect(queue.isEmpty, true);
    });

    test('Circular wrapping works correctly', () {
      final queue = MovementQueue.create(3);

      // Enqueue 3 elements
      queue.enqueue(10);
      queue.enqueue(20);
      queue.enqueue(30);

      expect(queue.isFull, true);
      expect(queue.count, 3);

      // Dequeue 1 element, opening up space
      expect(queue.dequeue(), 10);
      expect(queue.isFull, false);
      expect(queue.count, 2);

      // Enqueue 1 element, which should wrap around to index 0 (metaSize + 0)
      queue.enqueue(40);
      expect(queue.isFull, true);
      expect(queue.count, 3);
      expect(queue.tail, 1); // Wrapped around

      // Dequeue the remaining elements
      expect(queue.dequeue(), 20);
      expect(queue.dequeue(), 30);
      expect(queue.dequeue(), 40);
      expect(queue.isEmpty, true);
    });

    test('Clear resets the queue', () {
      final queue = MovementQueue.create(3);
      queue.enqueue(10);
      queue.enqueue(20);

      expect(queue.count, 2);

      queue.clear();

      expect(queue.count, 0);
      expect(queue.head, 0);
      expect(queue.tail, 0);
      expect(queue.isEmpty, true);
    });

    test('Enqueuing when full does nothing', () {
      final queue = MovementQueue.create(2);
      queue.enqueue(10);
      queue.enqueue(20);

      expect(queue.isFull, true);

      queue.enqueue(30); // Should be ignored

      expect(queue.count, 2);
      expect(queue.dequeue(), 10);
      expect(queue.dequeue(), 20);
      expect(queue.isEmpty, true);
    });
  });
}
