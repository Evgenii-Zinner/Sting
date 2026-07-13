import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/nav_mesh.dart';
import 'package:sting/engine/math/nav_mesh_pathfinder.dart';

void main() {
  group('NavMesh', () {
    test('addPolygon and getPolygon work', () {
      final navMesh = NavMesh();
      final poly = NavPolygon(0, [0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]);
      navMesh.addPolygon(poly);

      expect(navMesh.polygonCount, 1);
      expect(navMesh.getPolygon(0), equals(poly));
      expect(navMesh.getPolygon(1), isNull);
    });

    test('findPolygon correctly identifies point inside polygon', () {
      final navMesh = NavMesh();
      // 10x10 square
      navMesh.addPolygon(NavPolygon(0, [0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]));
      // Triangle adjacent
      navMesh.addPolygon(NavPolygon(1, [10.0, 20.0, 10.0], [0.0, 5.0, 10.0]));

      expect(navMesh.findPolygon(5.0, 5.0), 0);
      expect(navMesh.findPolygon(12.0, 5.0), 1);
      expect(navMesh.findPolygon(20.0, 20.0), -1);
    });

    test('buildNeighbors correctly connects adjacent polygons', () {
      final navMesh = NavMesh();
      // Poly 0: square 0..10
      navMesh.addPolygon(NavPolygon(0, [0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]));
      // Poly 1: square 10..20, sharing edge x=10, y:0..10
      navMesh.addPolygon(NavPolygon(1, [10.0, 20.0, 20.0, 10.0], [0.0, 0.0, 10.0, 10.0]));

      navMesh.buildNeighbors();

      final poly0 = navMesh.getPolygon(0)!;
      final poly1 = navMesh.getPolygon(1)!;

      // Edge 1 of poly0 (10,0 to 10,10) should connect to poly1
      expect(poly0.neighbors[1], 1);
      // Edge 3 of poly1 (10,10 to 10,0) should connect to poly0
      expect(poly1.neighbors[3], 0);

      // Other edges should be -1
      expect(poly0.neighbors[0], -1);
      expect(poly1.neighbors[0], -1);
    });

    test('carveAABB disconnects intersecting polygons', () {
      final navMesh = NavMesh();
      navMesh.addPolygon(NavPolygon(0, [0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]));
      navMesh.addPolygon(NavPolygon(1, [10.0, 20.0, 20.0, 10.0], [0.0, 0.0, 10.0, 10.0]));
      navMesh.addPolygon(NavPolygon(2, [20.0, 30.0, 30.0, 20.0], [0.0, 0.0, 10.0, 10.0]));

      navMesh.buildNeighbors();

      expect(navMesh.getPolygon(0)!.neighbors[1], 1);
      expect(navMesh.getPolygon(1)!.neighbors[3], 0);
      expect(navMesh.getPolygon(1)!.neighbors[1], 2);
      expect(navMesh.getPolygon(2)!.neighbors[3], 1);

      // Carve out a block in the middle of poly 1
      navMesh.carveAABB(12.0, 2.0, 18.0, 8.0);

      // Poly 1 is "disabled" via carve, so connections to/from it should be -1
      expect(navMesh.getPolygon(0)!.neighbors[1], -1);
      expect(navMesh.getPolygon(1)!.neighbors[3], -1);
      expect(navMesh.getPolygon(1)!.neighbors[1], -1);
      expect(navMesh.getPolygon(2)!.neighbors[3], -1);

      expect(navMesh.getPolygon(1)!.isTraversable, isFalse);
    });
  });

  group('NavMeshPathfinder', () {
    late NavMesh navMesh;
    late NavMeshPathfinder pathfinder;

    setUp(() {
      navMesh = NavMesh();
      // Setup a small corridor
      // Poly 0: (0,0) to (10,10)
      navMesh.addPolygon(NavPolygon(0, [0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]));
      // Poly 1: (10,0) to (20,10)
      navMesh.addPolygon(NavPolygon(1, [10.0, 20.0, 20.0, 10.0], [0.0, 0.0, 10.0, 10.0]));
      // Poly 2: (20,0) to (30,10)
      navMesh.addPolygon(NavPolygon(2, [20.0, 30.0, 30.0, 20.0], [0.0, 0.0, 10.0, 10.0]));
      navMesh.buildNeighbors();

      pathfinder = NavMeshPathfinder(navMesh, 10, 20);
    });

    test('findPath returns straight line within same polygon', () {
      final pointCount = pathfinder.findPath(2.0, 2.0, 8.0, 8.0);
      expect(pointCount, 2);
      expect(pathfinder.outPathX[0], 2.0);
      expect(pathfinder.outPathY[0], 2.0);
      expect(pathfinder.outPathX[1], 8.0);
      expect(pathfinder.outPathY[1], 8.0);
    });

    test('findPath works across multiple polygons using Funnel', () {
      final pointCount = pathfinder.findPath(2.0, 5.0, 28.0, 5.0);

      expect(pointCount, greaterThanOrEqualTo(2));
      expect(pathfinder.outPathX[0], 2.0);
      expect(pathfinder.outPathY[0], 5.0);
      expect(pathfinder.outPathX[pointCount - 1], 28.0);
      expect(pathfinder.outPathY[pointCount - 1], 5.0);
    });

    test('findPath handles complex funnel around a corner', () {
      final correctLShape = NavMesh();
      // Poly 0: bottom part of vertical bar: 0..10, 0..20
      correctLShape.addPolygon(NavPolygon(0, [0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 20.0, 20.0]));
      // Poly 1: top part of vertical bar (intersection): 0..10, 20..30
      correctLShape.addPolygon(NavPolygon(1, [0.0, 10.0, 10.0, 0.0], [20.0, 20.0, 30.0, 30.0]));
      // Poly 2: horizontal bar: 10..40, 20..30
      correctLShape.addPolygon(NavPolygon(2, [10.0, 40.0, 40.0, 10.0], [20.0, 20.0, 30.0, 30.0]));
      correctLShape.buildNeighbors();

      final lPathfinder = NavMeshPathfinder(correctLShape, 10, 20);

      // Start at bottom of vertical bar, target at right of horizontal bar
      final count = lPathfinder.findPath(5.0, 5.0, 35.0, 25.0);

      expect(count, greaterThan(0));
      // First point is start
      expect(lPathfinder.outPathX[0], 5.0);
      expect(lPathfinder.outPathY[0], 5.0);
      // Last point is target
      expect(lPathfinder.outPathX[count - 1], 35.0);
      expect(lPathfinder.outPathY[count - 1], 25.0);
    });

    test('findPath returns 0 when unreachable due to carved obstacle', () {
      // First ensure it's reachable normally
      final initialCount = pathfinder.findPath(2.0, 5.0, 28.0, 5.0);
      expect(initialCount, greaterThan(0));

      // Carve obstacle blocking middle polygon
      navMesh.carveAABB(12.0, 2.0, 18.0, 8.0);

      final pointCount = pathfinder.findPath(2.0, 5.0, 28.0, 5.0);
      expect(pointCount, 0); // No path from poly 0 to poly 2
    });

    test('findPath returns 0 when starting or ending outside nav mesh', () {
       expect(pathfinder.findPath(-10.0, 5.0, 28.0, 5.0), 0);
       expect(pathfinder.findPath(2.0, 5.0, 100.0, 100.0), 0);
    });
  });

  group('_NavMinHeap (via NavMeshPathfinder)', () {
    test('handles pathfinding that requires heap updates', () {
       final heapMesh = NavMesh();
       // 4 polys arranged in a square
       // 0 - 1
       // |   |
       // 2 - 3
       heapMesh.addPolygon(NavPolygon(0, [0.0, 10.0, 10.0, 0.0], [0.0, 0.0, 10.0, 10.0]));
       heapMesh.addPolygon(NavPolygon(1, [10.0, 20.0, 20.0, 10.0], [0.0, 0.0, 10.0, 10.0]));
       heapMesh.addPolygon(NavPolygon(2, [0.0, 10.0, 10.0, 0.0], [10.0, 10.0, 20.0, 20.0]));
       heapMesh.addPolygon(NavPolygon(3, [10.0, 20.0, 20.0, 10.0], [10.0, 10.0, 20.0, 20.0]));
       heapMesh.buildNeighbors();

       final pathfinder = NavMeshPathfinder(heapMesh, 10, 20);
       final count = pathfinder.findPath(5.0, 5.0, 15.0, 15.0);
       expect(count, greaterThan(0));
    });
  });
}
