import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/systems/pathfinding_system.dart';
import 'package:sting/engine/components/movement_queue.dart';

void main() {
  group('GridPathfinder', () {
    late GridPathfinder pathfinder;
    late MovementQueue queue;

    setUp(() {
      pathfinder = GridPathfinder(100);
      queue = MovementQueue.create(100);
    });

    test('finds path on a 4-way rectangular grid', () {
      // 5x5 grid
      // S . . . .
      // . X X X .
      // . . . X .
      // X X . X .
      // . . . . T
      final costGrid = Int32List(25)..fillRange(0, 25, 1);
      costGrid[6] = 0; // X
      costGrid[7] = 0; // X
      costGrid[8] = 0; // X
      costGrid[13] = 0; // X
      costGrid[15] = 0; // X
      costGrid[16] = 0; // X
      costGrid[18] = 0; // X

      final success = pathfinder.findPath(0, 24, costGrid, 5, 5, GridType.rectangular, queue);

      expect(success, isTrue);
      expect(queue.isEmpty, isFalse);

      final path = <int>[];
      while (!queue.isEmpty) {
        path.add(queue.dequeue());
      }

      expect(path.first, equals(0));
      expect(path.last, equals(24));
      // Verify no diagonal moves
      for (int i = 0; i < path.length - 1; i++) {
        final current = path[i];
        final next = path[i + 1];
        final cx = current % 5;
        final cy = current ~/ 5;
        final nx = next % 5;
        final ny = next ~/ 5;
        expect((cx - nx).abs() + (cy - ny).abs(), equals(1));
      }
    });

    test('finds path on an 8-way rectangular grid without corner cutting', () {
      // 3x3 grid
      // S X .
      // . X .
      // . . T
      final costGrid = Int32List(9)..fillRange(0, 9, 1);
      costGrid[1] = 0; // X
      costGrid[4] = 0; // X

      final success = pathfinder.findPath(0, 8, costGrid, 3, 3, GridType.rectangular8Way, queue);

      expect(success, isTrue);
      expect(queue.isEmpty, isFalse);

      final path = <int>[];
      while (!queue.isEmpty) {
        path.add(queue.dequeue());
      }

      expect(path.first, equals(0));
      expect(path.last, equals(8));
      // Should go down and around, not cut the corner at S(0) -> (2) since (1) and (4) are blocked.
      expect(path.contains(3), isTrue);
      expect(path.contains(6), isTrue);
    });

    test('finds path on a hexagonal grid', () {
       // 3x3 grid
      final costGrid = Int32List(9)..fillRange(0, 9, 1);

      final success = pathfinder.findPath(0, 8, costGrid, 3, 3, GridType.hexagonal, queue);

      expect(success, isTrue);

      final path = <int>[];
      while (!queue.isEmpty) {
        path.add(queue.dequeue());
      }
      expect(path.first, equals(0));
      expect(path.last, equals(8));
    });

    test('returns false when target is unreachable', () {
      // 3x3 grid
      // S X T
      // . X .
      // . X .
      final costGrid = Int32List(9)..fillRange(0, 9, 1);
      costGrid[1] = 0;
      costGrid[4] = 0;
      costGrid[7] = 0;

      final success = pathfinder.findPath(0, 2, costGrid, 3, 3, GridType.rectangular, queue);

      expect(success, isFalse);
      expect(queue.isEmpty, isTrue);
    });

    test('returns false for invalid start/target', () {
      final costGrid = Int32List(9)..fillRange(0, 9, 1);

      expect(pathfinder.findPath(-1, 8, costGrid, 3, 3, GridType.rectangular, queue), isFalse);
      expect(pathfinder.findPath(0, 100, costGrid, 3, 3, GridType.rectangular, queue), isFalse);
    });

    test('returns false if total nodes exceed capacity', () {
       final costGrid = Int32List(200)..fillRange(0, 200, 1);
       // capacity is 100, we try to use a 10x20 grid
       expect(pathfinder.findPath(0, 199, costGrid, 10, 20, GridType.rectangular, queue), isFalse);
    });

    test('returns false if start or target is an obstacle', () {
      final costGrid = Int32List(9)..fillRange(0, 9, 1);
      costGrid[0] = 0; // S is obstacle
      expect(pathfinder.findPath(0, 8, costGrid, 3, 3, GridType.rectangular, queue), isFalse);

      costGrid[0] = 1;
      costGrid[8] = 0; // T is obstacle
      expect(pathfinder.findPath(0, 8, costGrid, 3, 3, GridType.rectangular, queue), isFalse);
    });
  });

  group('_MinHeap (via GridPathfinder)', () {
    test('handles pathfinding that requires heap updates', () {
      final pathfinder = GridPathfinder(100);
      final queue = MovementQueue.create(100);
      // Need a scenario where a node is found again with a lower gScore
      // This is rare in standard grids with uniform cost, but we can simulate it with variable costs

      // 3x3 grid
      // S A B
      // C D E
      // F G T
      final costGrid = Int32List(9)..fillRange(0, 9, 1);
      costGrid[1] = 10; // A is very expensive
      costGrid[3] = 1;  // C is cheap
      costGrid[4] = 1;  // D is cheap

      pathfinder.findPath(0, 8, costGrid, 3, 3, GridType.rectangular, queue);

      final path = <int>[];
      while (!queue.isEmpty) {
        path.add(queue.dequeue());
      }
      // Should avoid A (1)
      expect(path.contains(1), isFalse);
    });
  });
}
