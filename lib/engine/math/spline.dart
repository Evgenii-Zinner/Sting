/// Zero-allocation mathematical utilities for 2D splines.
class SplineMath {
  /// Evaluates a quadratic Bezier curve at parameter [t] (0.0 to 1.0).
  ///
  /// The curve is defined by a start point (p0), a control point (p1), and an end point (p2).
  static (double, double) evaluateQuadraticBezier(
    double p0x, double p0y,
    double p1x, double p1y,
    double p2x, double p2y,
    double t,
  ) {
    final double u = 1.0 - t;
    final double tt = t * t;
    final double uu = u * u;

    final double x = uu * p0x + 2 * u * t * p1x + tt * p2x;
    final double y = uu * p0y + 2 * u * t * p1y + tt * p2y;

    return (x, y);
  }

  /// Evaluates a cubic Bezier curve at parameter [t] (0.0 to 1.0).
  ///
  /// The curve is defined by a start point (p0), two control points (p1, p2), and an end point (p3).
  static (double, double) evaluateCubicBezier(
    double p0x, double p0y,
    double p1x, double p1y,
    double p2x, double p2y,
    double p3x, double p3y,
    double t,
  ) {
    final double u = 1.0 - t;
    final double tt = t * t;
    final double uu = u * u;
    final double uuu = uu * u;
    final double ttt = tt * t;

    final double x = uuu * p0x + 3 * uu * t * p1x + 3 * u * tt * p2x + ttt * p3x;
    final double y = uuu * p0y + 3 * uu * t * p1y + 3 * u * tt * p2y + ttt * p3y;

    return (x, y);
  }

  /// Evaluates a cubic Hermite spline at parameter [t] (0.0 to 1.0).
  ///
  /// The curve is defined by a start point (p0), start tangent (t0), end point (p1), and end tangent (t1).
  static (double, double) evaluateHermite(
    double p0x, double p0y,
    double t0x, double t0y,
    double p1x, double p1y,
    double t1x, double t1y,
    double t,
  ) {
    final double tt = t * t;
    final double ttt = tt * t;

    // Basis functions
    final double h00 = 2 * ttt - 3 * tt + 1;
    final double h10 = ttt - 2 * tt + t;
    final double h01 = -2 * ttt + 3 * tt;
    final double h11 = ttt - tt;

    final double x = h00 * p0x + h10 * t0x + h01 * p1x + h11 * t1x;
    final double y = h00 * p0y + h10 * t0y + h01 * p1y + h11 * t1y;

    return (x, y);
  }
}
