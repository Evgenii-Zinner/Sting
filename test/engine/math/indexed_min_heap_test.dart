import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/indexed_min_heap.dart';

void main() {
  group('IndexedMinHeap Tests', () {
    test('Initialization sets correct defaults and capacity', () {
      final fScore = Float32List(10);
      final heap = IndexedMinHeap(10, fScore);

      expect(heap.size, equals(0));
      expect(heap.isEmpty, isTrue);
      expect(heap.pop(), equals(-1));
    });

    test('Push and pop in correct priority order', () {
      final fScore = Float32List(5);
      fScore[0] = 50.0;
      fScore[1] = 10.0;
      fScore[2] = 30.0;
      fScore[3] = 5.0;
      fScore[4] = 20.0;

      final heap = IndexedMinHeap(5, fScore);
      heap.push(0);
      heap.push(1);
      heap.push(2);
      heap.push(3);
      heap.push(4);

      expect(heap.size, equals(5));
      expect(heap.isEmpty, isFalse);

      expect(heap.pop(), equals(3)); // score 5.0
      expect(heap.pop(), equals(1)); // score 10.0
      expect(heap.pop(), equals(4)); // score 20.0
      expect(heap.pop(), equals(2)); // score 30.0
      expect(heap.pop(), equals(0)); // score 50.0
      expect(heap.pop(), equals(-1));
      expect(heap.isEmpty, isTrue);
    });

    test('decreaseKey correctly re-heaps element upward', () {
      final fScore = Float32List(4);
      fScore[0] = 100.0;
      fScore[1] = 200.0;
      fScore[2] = 300.0;

      final heap = IndexedMinHeap(4, fScore);
      heap.push(0);
      heap.push(1);
      heap.push(2);

      // Decrease key of node 2 so it becomes top priority
      fScore[2] = 10.0;
      heap.decreaseKey(2);

      expect(heap.pop(), equals(2));
      expect(heap.pop(), equals(0));
      expect(heap.pop(), equals(1));
    });

    test('clear resets heap and tracked indices', () {
      final fScore = Float32List(5);
      fScore[0] = 1.0;
      fScore[1] = 2.0;

      final heap = IndexedMinHeap(5, fScore);
      heap.push(0);
      heap.push(1);

      expect(heap.size, equals(2));
      heap.clear();

      expect(heap.size, equals(0));
      expect(heap.isEmpty, isTrue);
      expect(heap.indices[0], equals(-1));
      expect(heap.indices[1], equals(-1));
    });
  });
}
