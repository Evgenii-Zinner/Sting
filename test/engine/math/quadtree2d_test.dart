import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/quadtree2d.dart';

void main() {
  group('QuadTree2D', () {
    late QuadTree2D quadtree;

    setUp(() {
      quadtree = QuadTree2D(
        0.0,
        0.0,
        100.0,
        100.0,
        maxEntitiesPerNode: 4,
        maxDepth: 4,
        maxNodes: 1000,
        maxElements: 1000,
      );
    });

    test('initialization sets correct default values', () {
      expect(quadtree.nodeCount, 1);
      expect(quadtree.elementCount, 0);
    });

    test('clear() resets tree but keeps root node', () {
      quadtree.insert(1, 10, 10, 20, 20);
      quadtree.insert(2, 80, 80, 90, 90);
      expect(quadtree.elementCount, 2);

      quadtree.clear();
      expect(quadtree.nodeCount, 1);
      expect(quadtree.elementCount, 0);

      final outEntities = Int32List(10);
      final count = quadtree.queryAABB(0, 0, 100, 100, outEntities);
      expect(count, 0);
    });

    test('insert() adds elements to root if within capacity', () {
      quadtree.insert(1, 10, 10, 20, 20);
      quadtree.insert(2, 30, 30, 40, 40);

      expect(quadtree.nodeCount, 1); // No subdivision yet
      expect(quadtree.elementCount, 2);

      final outEntities = Int32List(10);
      final count = quadtree.queryAABB(0, 0, 50, 50, outEntities);
      expect(count, 2);
      expect(outEntities.sublist(0, 2), unorderedEquals([1, 2]));
    });

    test('insert() triggers subdivision when capacity exceeded', () {
      // Insert 5 elements (max capacity is 4)
      quadtree.insert(1, 10, 10, 20, 20); // NW
      quadtree.insert(2, 60, 10, 70, 20); // NE
      quadtree.insert(3, 10, 60, 20, 70); // SW
      quadtree.insert(4, 60, 60, 70, 70); // SE

      expect(quadtree.nodeCount, 1);

      quadtree.insert(5, 15, 15, 25, 25); // NW again, triggers subdivide

      expect(quadtree.nodeCount, 5); // Root + 4 children
      expect(quadtree.elementCount, 5);

      final outEntitiesNW = Int32List(10);
      final countNW = quadtree.queryAABB(0, 0, 49, 49, outEntitiesNW);
      expect(countNW, 2);
      expect(outEntitiesNW.sublist(0, 2), unorderedEquals([1, 5]));

      final outEntitiesNE = Int32List(10);
      final countNE = quadtree.queryAABB(51, 0, 100, 49, outEntitiesNE);
      expect(countNE, 1);
      expect(outEntitiesNE[0], 2);
    });

    test('elements crossing boundaries stay in parent', () {
      // Create children
      quadtree.insert(1, 10, 10, 20, 20);
      quadtree.insert(2, 60, 10, 70, 20);
      quadtree.insert(3, 10, 60, 20, 70);
      quadtree.insert(4, 60, 60, 70, 70);
      quadtree.insert(5, 15, 15, 25, 25); // Trigger subdivide

      expect(quadtree.nodeCount, 5);

      // Insert element crossing the center lines (x=50, y=50)
      quadtree.insert(6, 40, 40, 60, 60);

      final outEntities = Int32List(10);
      final count = quadtree.queryAABB(45, 45, 55, 55, outEntities);
      expect(count, 1);
      expect(outEntities[0], 6);
    });

    test('queryAABB() caps out at provided buffer size', () {
      for (int i = 0; i < 10; i++) {
        quadtree.insert(i, 10.0 + i, 10.0 + i, 20.0 + i, 20.0 + i);
      }

      final smallBuffer = Int32List(5);
      final count = quadtree.queryAABB(0, 0, 100, 100, smallBuffer);

      expect(count, 5);
      expect(smallBuffer.length, 5);
    });

    test('queryAABB() excludes elements fully outside query region', () {
      quadtree.insert(1, 10, 10, 20, 20);
      quadtree.insert(2, 80, 80, 90, 90);

      final outEntities = Int32List(10);
      final count = quadtree.queryAABB(0, 0, 30, 30, outEntities);

      expect(count, 1);
      expect(outEntities[0], 1);
    });

    test('stress test for zero-allocation verification', () {
      // Since this runs in Dart VM, we can't strictly assert zero allocations easily,
      // but we can ensure it completes very fast and doesn't crash on high entity counts.
      final qt = QuadTree2D(
        0,
        0,
        1000,
        1000,
        maxEntitiesPerNode: 10,
        maxDepth: 6,
        maxNodes: 5000,
        maxElements: 10000,
      );

      for (int i = 0; i < 5000; i++) {
        double x = (i * 13) % 900;
        double y = (i * 17) % 900;
        qt.insert(i, x, y, x + 10, y + 10);
      }

      expect(qt.elementCount, 5000);
      expect(qt.nodeCount > 1, isTrue);

      final outEntities = Int32List(100);
      int totalQueries = 0;

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        double qx = (i * 7) % 900;
        double qy = (i * 11) % 900;
        totalQueries += qt.queryAABB(qx, qy, qx + 50, qy + 50, outEntities);
      }
      stopwatch.stop();

      // Stress test should run in a fraction of a second
      expect(stopwatch.elapsedMilliseconds < 500, isTrue);
      expect(totalQueries > 0, isTrue); // Should have found *something*
    });
  });
}
