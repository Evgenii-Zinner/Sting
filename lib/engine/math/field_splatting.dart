import 'dart:typed_data';

/// Utility class for zero-allocation continuous point deposition / splatting
/// onto discrete 2D float grids.
class FieldSplatting {
  /// Distributes [amount] across the 4 surrounding discrete cells inversely
  /// proportional to distance.
  ///
  /// Bounds-checked, handles edge clipping safely.
  /// If [maxCap] is provided, the resulting values in the cells will not exceed [maxCap].
  static void splatBilinear(
    Float32List grid,
    int cols,
    int rows,
    double x,
    double y,
    double amount, [
    double? maxCap,
  ]) {
    final x0 = x.floor();
    final y0 = y.floor();
    final x1 = x0 + 1;
    final y1 = y0 + 1;

    final dx = x - x0;
    final dy = y - y0;

    final w00 = (1.0 - dx) * (1.0 - dy);
    final w10 = dx * (1.0 - dy);
    final w01 = (1.0 - dx) * dy;
    final w11 = dx * dy;

    _addAt(grid, cols, rows, x0, y0, amount * w00, maxCap);
    _addAt(grid, cols, rows, x1, y0, amount * w10, maxCap);
    _addAt(grid, cols, rows, x0, y1, amount * w01, maxCap);
    _addAt(grid, cols, rows, x1, y1, amount * w11, maxCap);
  }

  /// Applies Gaussian or quadratic radial falloff to cells within the [radius].
  ///
  /// Bounds-checked, handles edge clipping safely.
  /// If [maxCap] is provided, the resulting values in the cells will not exceed [maxCap].
  static void splatRadialGaussian(
    Float32List grid,
    int cols,
    int rows,
    double centerX,
    double centerY,
    double radius,
    double peakValue, [
    double? maxCap,
  ]) {
    if (radius <= 0) return;

    final minX = (centerX - radius).floor().clamp(0, cols - 1);
    final maxX = (centerX + radius).ceil().clamp(0, cols - 1);
    final minY = (centerY - radius).floor().clamp(0, rows - 1);
    final maxY = (centerY + radius).ceil().clamp(0, rows - 1);

    final rSq = radius * radius;

    for (var y = minY; y <= maxY; y++) {
      final dy = centerY - y;
      final dySq = dy * dy;

      for (var x = minX; x <= maxX; x++) {
        final dx = centerX - x;
        final distSq = dx * dx + dySq;

        if (distSq <= rSq) {
          // Quadratic falloff approximation
          final falloff = 1.0 - (distSq / rSq);
          final amount = peakValue * falloff;

          final index = y * cols + x;
          final current = grid[index];
          var next = current + amount;

          if (maxCap != null && next > maxCap) {
            next = maxCap;
            // Never lower the value if it was already above maxCap
            if (current > maxCap) {
              next = current;
            }
          }
          grid[index] = next;
        }
      }
    }
  }

  static void _addAt(
    Float32List grid,
    int cols,
    int rows,
    int x,
    int y,
    double amount,
    double? maxCap,
  ) {
    if (x < 0 || x >= cols || y < 0 || y >= rows) return;

    final index = y * cols + x;
    final current = grid[index];
    var next = current + amount;

    if (maxCap != null && next > maxCap) {
      next = maxCap;
      // Never lower the value if it was already above maxCap
      if (current > maxCap) {
        next = current;
      }
    }

    grid[index] = next;
  }
}
