import 'dart:typed_data';
import 'dart:math' as math;

/// Utility class for calculating numerical gradients from continuous 2D scalar fields.
/// Designed for zero-allocation computation per frame.
class FieldGradient {
  /// Computes the central finite difference gradient at (x, y) on a scalar grid.
  ///
  /// Uses bilinear interpolation to allow for continuous sampling.
  /// [epsilon] determines the sampling step size for finite differences.
  /// If [normalize] is true, the resulting vector (dx, dy) is normalized.
  /// Returns a Dart 3 record containing (dx, dy, magnitude) without allocations.
  static ({double dx, double dy, double magnitude}) computeGradient(
    Float32List grid,
    int cols,
    int rows,
    double x,
    double y, {
    double epsilon = 1.0,
    bool normalize = false,
  }) {
    // Sample using central difference
    final double right = _sample(grid, cols, rows, x + epsilon, y);
    final double left = _sample(grid, cols, rows, x - epsilon, y);
    final double top = _sample(grid, cols, rows, x, y - epsilon);
    final double bottom = _sample(grid, cols, rows, x, y + epsilon);

    double dx = (right - left) / (2 * epsilon);
    double dy = (bottom - top) / (2 * epsilon); // y axis down convention

    final double magnitudeSquared = dx * dx + dy * dy;
    final double magnitude =
        magnitudeSquared > 0 ? math.sqrt(magnitudeSquared) : 0.0;

    if (normalize && magnitude > 0) {
      dx /= magnitude;
      dy /= magnitude;
    }

    return (dx: dx, dy: dy, magnitude: magnitude);
  }

  /// Bilinear interpolation sampler with boundary clamping.
  static double _sample(
      Float32List grid, int cols, int rows, double x, double y) {
    // Clamp to valid grid coordinates
    final double cx = x.clamp(0.0, (cols - 1).toDouble());
    final double cy = y.clamp(0.0, (rows - 1).toDouble());

    final int x0 = cx.floor();
    final int x1 = math.min(x0 + 1, cols - 1);
    final int y0 = cy.floor();
    final int y1 = math.min(y0 + 1, rows - 1);

    final double tx = cx - x0;
    final double ty = cy - y0;

    final double v00 = grid[y0 * cols + x0];
    final double v10 = grid[y0 * cols + x1];
    final double v01 = grid[y1 * cols + x0];
    final double v11 = grid[y1 * cols + x1];

    final double interpTop = v00 * (1 - tx) + v10 * tx;
    final double interpBottom = v01 * (1 - tx) + v11 * tx;

    return interpTop * (1 - ty) + interpBottom * ty;
  }
}
