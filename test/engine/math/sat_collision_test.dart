import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/sat_collision.dart';

void main() {
  group('SAT Collision - Polygon vs Polygon', () {
    late SATCollisionResult result;

    setUp(() {
      result = SATCollisionResult();
    });

    test('Separation on PolyB axis but not PolyA axis', () {
      final polyA = Float32List.fromList([
        0, 0,
        10, 0,
        10, 10,
        0, 10
      ]);
      final polyB = Float32List.fromList([
        11.5, 9.5,
        13.5, 11.5,
        11.5, 13.5,
        9.5, 11.5
      ]);

      testPolygonPolygon(polyA, 4, polyB, 4, result);
      expect(result.intersects, isFalse);
    });

    test('Non-intersecting separated squares', () {
      final polyA = Float32List.fromList([
        0, 0,
        10, 0,
        10, 10,
        0, 10
      ]);
      final polyB = Float32List.fromList([
        20, 20,
        30, 20,
        30, 30,
        20, 30
      ]);

      testPolygonPolygon(polyA, 4, polyB, 4, result);
      expect(result.intersects, isFalse);
    });

    test('Intersecting squares', () {
      final polyA = Float32List.fromList([
        0, 0,
        10, 0,
        10, 10,
        0, 10
      ]);
      final polyB = Float32List.fromList([
        5, 5,
        15, 5,
        15, 15,
        5, 15
      ]);

      testPolygonPolygon(polyA, 4, polyB, 4, result);
      expect(result.intersects, isTrue);
      expect(result.depth, closeTo(5.0, 0.001));
      // normal points from A to B
      // Normal could be (1, 0) or (0, 1) depending on which axis was tested first
      expect(result.normalX.abs() + result.normalY.abs(), closeTo(1.0, 0.001));
      expect(result.normalX * result.normalY, closeTo(0.0, 0.001));
    });

    test('Intersecting squares - check correct normal selection when depths differ', () {
      final polyA = Float32List.fromList([
        0, 0,
        10, 0,
        10, 10,
        0, 10
      ]);
      // Poly B overlaps by 2 units on X axis, 8 units on Y axis
      final polyB = Float32List.fromList([
        8, 2,
        18, 2,
        18, 12,
        8, 12
      ]);

      testPolygonPolygon(polyA, 4, polyB, 4, result);
      expect(result.intersects, isTrue);
      expect(result.depth, closeTo(2.0, 0.001));
      // normal should be along X-axis because penetration depth is smaller along X (2.0) than Y (8.0)
      expect(result.normalX, closeTo(1.0, 0.001));
      expect(result.normalY, closeTo(0.0, 0.001));
    });

    test('Containment', () {
      final polyA = Float32List.fromList([
        0, 0,
        10, 0,
        10, 10,
        0, 10
      ]);
      final polyB = Float32List.fromList([
        2, 2,
        8, 2,
        8, 8,
        2, 8
      ]);

      testPolygonPolygon(polyA, 4, polyB, 4, result);
      expect(result.intersects, isTrue);
      expect(result.depth, closeTo(8.0, 0.001));
    });

    test('Triangle vs Square overlapping', () {
      final polyA = Float32List.fromList([
        0, 0,
        10, 0,
        5, 10
      ]);
      final polyB = Float32List.fromList([
        4, 5,
        14, 5,
        14, 15,
        4, 15
      ]);

      testPolygonPolygon(polyA, 3, polyB, 4, result);
      expect(result.intersects, isTrue);
    });

    test('Zero length edge handling (prevent NaN)', () {
      final polyA = Float32List.fromList([
        0, 0,
        0, 0, // Duplicate vertex creates 0-length edge
        10, 10,
        0, 10
      ]);
      final polyB = Float32List.fromList([
        5, 5,
        15, 5,
        15, 15,
        5, 15
      ]);

      testPolygonPolygon(polyA, 4, polyB, 4, result);
      expect(result.intersects, isTrue); // Should be true since they overlap
    });
  });

  group('SAT Collision - Polygon vs Circle', () {
    late SATCollisionResult result;

    setUp(() {
      result = SATCollisionResult();
    });

    test('Circle separates on vertex axis but overlaps on edge axes', () {
      final poly = Float32List.fromList([
        0, 0,
        10, 0,
        10, 10,
        0, 10
      ]);
      // Circle at (11.5, 11.5) with radius 2.
      // Projections on X and Y axes overlap poly, but distance to (10,10) is ~2.12 > 2.0.
      testPolygonCircle(poly, 4, 11.5, 11.5, 2.0, result);
      expect(result.intersects, isFalse);
    });

    test('Separated Polygon and Circle', () {
      final poly = Float32List.fromList([
        0, 0,
        10, 0,
        10, 10,
        0, 10
      ]);
      testPolygonCircle(poly, 4, 20.0, 20.0, 5.0, result);
      expect(result.intersects, isFalse);
    });

    test('Intersecting Polygon and Circle (face)', () {
      final poly = Float32List.fromList([
        0, 0,
        10, 0,
        10, 10,
        0, 10
      ]);
      // Circle at x=12, y=5, radius=4. Intersects right face of square (x=10).
      testPolygonCircle(poly, 4, 12.0, 5.0, 4.0, result);
      expect(result.intersects, isTrue);
      // Penetration depth should be 2.0 (circle left edge is at 8, square right edge is at 10)
      expect(result.depth, closeTo(2.0, 0.001));
      // Normal should point from poly to circle (right direction)
      expect(result.normalX, closeTo(1.0, 0.001));
      expect(result.normalY, closeTo(0.0, 0.001));
    });

    test('Intersecting Polygon and Circle (corner)', () {
      final poly = Float32List.fromList([
        0, 0,
        10, 0,
        10, 10,
        0, 10
      ]);
      // Circle at x=12, y=12, radius=4. Intersects top-right corner (10, 10).
      // Distance from (12,12) to (10,10) is sqrt(8) ~ 2.828. Radius is 4.
      testPolygonCircle(poly, 4, 12.0, 12.0, 4.0, result);
      expect(result.intersects, isTrue);
      // Depth = 4.0 - 2.828 = 1.1715
      expect(result.depth, closeTo(4.0 - 2.828427, 0.001));
      // Normal points from poly to circle, roughly (0.707, 0.707)
      expect(result.normalX, closeTo(0.707106, 0.001));
      expect(result.normalY, closeTo(0.707106, 0.001));
    });

    test('Circle fully inside Polygon', () {
      final poly = Float32List.fromList([
        0, 0,
        10, 0,
        10, 10,
        0, 10
      ]);
      testPolygonCircle(poly, 4, 5.0, 5.0, 2.0, result);
      expect(result.intersects, isTrue);
    });

    test('Circle center exactly on vertex', () {
      final poly = Float32List.fromList([
        0, 0,
        10, 0,
        10, 10,
        0, 10
      ]);
      // Center at origin
      testPolygonCircle(poly, 4, 0.0, 0.0, 5.0, result);
      expect(result.intersects, isTrue);
      expect(result.depth, closeTo(5.0, 0.001));
    });
  });
}
