import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/segment.dart';

void main() {
  group('SegmentMath', () {
    test('closestPointOnSegment returns exact point when segment is a point', () {
      final (x, y) = SegmentMath.closestPointOnSegment(10, 10, 10, 10, 5, 5);
      expect(x, 10.0);
      expect(y, 10.0);
    });

    test('closestPointOnSegment returns end point when px, py is past x2, y2', () {
      final (x, y) = SegmentMath.closestPointOnSegment(0, 0, 10, 0, 15, 0);
      expect(x, 10.0);
      expect(y, 0.0);
    });

    test('closestPointOnSegment returns start point when px, py is past x1, y1', () {
      final (x, y) = SegmentMath.closestPointOnSegment(0, 0, 10, 0, -5, 0);
      expect(x, 0.0);
      expect(y, 0.0);
    });

    test('closestPointOnSegment returns projected point on segment', () {
      final (x, y) = SegmentMath.closestPointOnSegment(0, 0, 10, 0, 5, 5);
      expect(x, 5.0);
      expect(y, 0.0);
    });

    test('distanceToSegmentSquared and distanceToSegment', () {
      expect(SegmentMath.distanceToSegmentSquared(0, 0, 10, 0, 5, 5), 25.0);
      expect(SegmentMath.distanceToSegment(0, 0, 10, 0, 5, 5), 5.0);

      // Beyond endpoint
      expect(SegmentMath.distanceToSegment(0, 0, 10, 0, 15, 0), 5.0);
    });

    test('intersectSegmentCircle', () {
      expect(SegmentMath.intersectSegmentCircle(0, 0, 10, 0, 5, 5, 6), isTrue); // Intersects
      expect(SegmentMath.intersectSegmentCircle(0, 0, 10, 0, 5, 5, 4), isFalse); // Does not intersect
      expect(SegmentMath.intersectSegmentCircle(0, 0, 10, 0, 15, 0, 6), isTrue); // Intersects beyond endpoint
    });

    test('intersectSegmentAABB', () {
      // Segment fully inside AABB
      expect(SegmentMath.intersectSegmentAABB(5, 5, 6, 6, 0, 0, 10, 10), isTrue);

      // Segment crosses AABB boundaries
      expect(SegmentMath.intersectSegmentAABB(-5, 5, 15, 5, 0, 0, 10, 10), isTrue); // Horizontally
      expect(SegmentMath.intersectSegmentAABB(5, -5, 5, 15, 0, 0, 10, 10), isTrue); // Vertically

      // Segment completely outside AABB
      expect(SegmentMath.intersectSegmentAABB(15, 15, 20, 20, 0, 0, 10, 10), isFalse);
    });
  });
}
