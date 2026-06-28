import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/intersection.dart';

void main() {
  group('Intersection Math', () {
    test('intersectAABBAABB returns true for overlapping boxes', () {
      expect(
        intersectAABBAABB(
          0.0, 0.0, 10.0, 10.0,
          5.0, 5.0, 10.0, 10.0,
        ),
        isTrue,
      );
    });

    test('intersectAABBAABB returns false for non-overlapping boxes', () {
      expect(
        intersectAABBAABB(
          0.0, 0.0, 10.0, 10.0,
          20.0, 20.0, 10.0, 10.0,
        ),
        isFalse,
      );
    });

    test('intersectAABBAABB returns false for touching boxes (exclusive)', () {
      expect(
        intersectAABBAABB(
          0.0, 0.0, 10.0, 10.0,
          10.0, 0.0, 10.0, 10.0,
        ),
        isFalse,
      );
      expect(
        intersectAABBAABB(
          0.0, 0.0, 10.0, 10.0,
          0.0, 10.0, 10.0, 10.0,
        ),
        isFalse,
      );
    });

    test('intersectAABBAABB returns true for fully contained box', () {
      expect(
        intersectAABBAABB(
          0.0, 0.0, 20.0, 20.0,
          5.0, 5.0, 10.0, 10.0,
        ),
        isTrue,
      );
    });

    test('intersectCircleCircle returns true for overlapping circles', () {
      expect(
        intersectCircleCircle(
          0.0, 0.0, 10.0,
          5.0, 0.0, 10.0,
        ),
        isTrue,
      );
    });

    test('intersectCircleCircle returns false for non-overlapping circles', () {
      expect(
        intersectCircleCircle(
          0.0, 0.0, 5.0,
          20.0, 20.0, 5.0,
        ),
        isFalse,
      );
    });

    test('intersectCircleCircle returns false for touching circles (exclusive)', () {
      expect(
        intersectCircleCircle(
          0.0, 0.0, 10.0,
          20.0, 0.0, 10.0,
        ),
        isFalse,
      );
    });

    test('intersectCircleCircle returns true for fully contained circle', () {
      expect(
        intersectCircleCircle(
          0.0, 0.0, 20.0,
          2.0, 2.0, 5.0,
        ),
        isTrue,
      );
    });

    test('intersectAABBCircle returns true for overlapping circle and AABB', () {
      // Circle center inside box
      expect(
        intersectAABBCircle(
          0.0, 0.0, 10.0, 10.0,
          5.0, 5.0, 5.0,
        ),
        isTrue,
      );

      // Circle center outside box, but intersecting
      expect(
        intersectAABBCircle(
          0.0, 0.0, 10.0, 10.0,
          12.0, 5.0, 5.0,
        ),
        isTrue,
      );
    });

    test('intersectAABBCircle returns false for non-overlapping circle and AABB', () {
      expect(
        intersectAABBCircle(
          0.0, 0.0, 10.0, 10.0,
          20.0, 20.0, 5.0,
        ),
        isFalse,
      );
    });

    test('intersectAABBCircle returns false for touching circle and AABB (exclusive)', () {
      expect(
        intersectAABBCircle(
          0.0, 0.0, 10.0, 10.0,
          15.0, 5.0, 5.0,
        ),
        isFalse,
      );
    });

    test('intersectAABBCircle handles corner intersections', () {
      // Circle intersects corner
      expect(
        intersectAABBCircle(
          0.0, 0.0, 10.0, 10.0,
          12.0, 12.0, 5.0,
        ),
        isTrue,
      );

      // Circle is near corner but does not intersect
      expect(
        intersectAABBCircle(
          0.0, 0.0, 10.0, 10.0,
          14.0, 14.0, 5.0,
        ),
        isFalse,
      );
    });
  });
}
