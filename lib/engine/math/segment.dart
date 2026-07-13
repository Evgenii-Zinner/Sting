import 'dart:math' as math;

/// Zero-allocation mathematical utilities for 2D line segments.
class SegmentMath {
  /// Finds the closest point on a line segment defined by (x1, y1) and (x2, y2)
  /// to a given point (px, py).
  static (double, double) closestPointOnSegment(
    double x1,
    double y1,
    double x2,
    double y2,
    double px,
    double py,
  ) {
    final double dx = x2 - x1;
    final double dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return (x1, y1);
    }

    // Calculate the t that minimizes the distance.
    double t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy);

    // Clamp t to the [0, 1] range to stay on the segment.
    if (t < 0) {
      t = 0;
    } else if (t > 1) {
      t = 1;
    }

    return (x1 + t * dx, y1 + t * dy);
  }

  /// Calculates the squared distance from a point (px, py) to a line segment
  /// defined by (x1, y1) and (x2, y2).
  static double distanceToSegmentSquared(
    double x1,
    double y1,
    double x2,
    double y2,
    double px,
    double py,
  ) {
    final (closestX, closestY) = closestPointOnSegment(x1, y1, x2, y2, px, py);
    final double dx = px - closestX;
    final double dy = py - closestY;
    return dx * dx + dy * dy;
  }

  /// Calculates the distance from a point (px, py) to a line segment
  /// defined by (x1, y1) and (x2, y2).
  static double distanceToSegment(
    double x1,
    double y1,
    double x2,
    double y2,
    double px,
    double py,
  ) {
    return math.sqrt(distanceToSegmentSquared(x1, y1, x2, y2, px, py));
  }

  /// Checks if a line segment defined by (x1, y1) and (x2, y2) intersects
  /// with a circle centered at (cx, cy) with radius r.
  /// This is equivalent to a capsule-sweep bounds check.
  static bool intersectSegmentCircle(
    double x1,
    double y1,
    double x2,
    double y2,
    double cx,
    double cy,
    double r,
  ) {
    final double distSq = distanceToSegmentSquared(x1, y1, x2, y2, cx, cy);
    return distSq <= r * r;
  }

  /// Checks if a line segment defined by (x1, y1) and (x2, y2) intersects
  /// with an Axis-Aligned Bounding Box defined by (rX, rY) and size (rW, rH).
  static bool intersectSegmentAABB(
    double x1,
    double y1,
    double x2,
    double y2,
    double rX,
    double rY,
    double rW,
    double rH,
  ) {
    // Check if either end of the segment is inside the AABB
    if (x1 >= rX && x1 <= rX + rW && y1 >= rY && y1 <= rY + rH) return true;
    if (x2 >= rX && x2 <= rX + rW && y2 >= rY && y2 <= rY + rH) return true;

    // Check intersection with AABB edges
    final double rX2 = rX + rW;
    final double rY2 = rY + rH;

    return _linesIntersect(x1, y1, x2, y2, rX, rY, rX2, rY) || // Top
           _linesIntersect(x1, y1, x2, y2, rX2, rY, rX2, rY2) || // Right
           _linesIntersect(x1, y1, x2, y2, rX2, rY2, rX, rY2) || // Bottom
           _linesIntersect(x1, y1, x2, y2, rX, rY2, rX, rY); // Left
  }

  // Helper for line segment intersection
  static bool _linesIntersect(
    double x1, double y1, double x2, double y2,
    double x3, double y3, double x4, double y4,
  ) {
    final double uA = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) /
        ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1));
    final double uB = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) /
        ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1));

    return uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1;
  }
}
