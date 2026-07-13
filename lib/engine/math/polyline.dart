import 'dart:math' as math;
import 'dart:typed_data';

/// Zero-allocation mathematical utilities for 2D polylines.
///
/// A polyline is represented by a flat [Float32List] where coordinates
/// are stored sequentially as [x0, y0, x1, y1, ...].
class PolylineMath {
  /// Calculates the total length of the polyline.
  static double length(Float32List points) {
    if (points.length < 4) return 0.0;

    double totalLength = 0.0;
    for (int i = 0; i < points.length - 2; i += 2) {
      final double dx = points[i + 2] - points[i];
      final double dy = points[i + 3] - points[i + 1];
      totalLength += math.sqrt(dx * dx + dy * dy);
    }

    return totalLength;
  }

  /// Evaluates the point on the polyline at parameter [t] (0.0 to 1.0).
  static (double, double) evaluateAt(Float32List points, double t) {
    if (points.isEmpty) return (0.0, 0.0);
    if (points.length < 4) return (points[0], points[1]);

    if (t <= 0.0) return (points[0], points[1]);
    if (t >= 1.0) return (points[points.length - 2], points[points.length - 1]);

    final double targetLength = length(points) * t;
    return evaluateAtDistance(points, targetLength);
  }

  /// Evaluates the point on the polyline at the specified [distance] from the start.
  static (double, double) evaluateAtDistance(Float32List points, double distance) {
    if (points.isEmpty) return (0.0, 0.0);
    if (points.length < 4) return (points[0], points[1]);

    if (distance <= 0.0) return (points[0], points[1]);

    double accumulatedLength = 0.0;

    for (int i = 0; i < points.length - 2; i += 2) {
      final double x1 = points[i];
      final double y1 = points[i + 1];
      final double x2 = points[i + 2];
      final double y2 = points[i + 3];

      final double dx = x2 - x1;
      final double dy = y2 - y1;
      final double segmentLength = math.sqrt(dx * dx + dy * dy);

      if (accumulatedLength + segmentLength >= distance) {
        // We found the segment containing the target distance
        final double remainingDistance = distance - accumulatedLength;
        final double tSegment = segmentLength > 0 ? remainingDistance / segmentLength : 0.0;

        return (x1 + tSegment * dx, y1 + tSegment * dy);
      }

      accumulatedLength += segmentLength;
    }

    // If we exceed the total length, return the last point
    return (points[points.length - 2], points[points.length - 1]);
  }
}
