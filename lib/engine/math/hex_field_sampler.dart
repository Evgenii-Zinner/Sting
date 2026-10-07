import 'dart:typed_data';
import 'dart:math' as math;
import 'package:sting/engine/math/hex_math.dart';

/// Zero-allocation mathematical utilities for sampling scalar fields on
/// flat-topped hexagonal grids.
///
/// Designed to extract values and gradients for moving agents continuously
/// without heap allocations per frame.
class HexFieldSampler {
  /// Samples a 2D scalar field at a given world position `(x, y)` on a
  /// flat-topped hexagonal grid.
  ///
  /// Uses [HexMath.flatWorldToGrid] to find the nearest axial coordinate,
  /// then maps it to a zero-indexed flat offset coordinate array (odd-q).
  ///
  /// [grid] is a flat Float32List representing a 2D grid.
  /// [cols] and [rows] define the grid dimensions.
  /// [hexSize] is the distance from center to corner.
  /// Out-of-bounds queries return 0.0 or the border value if clamped.
  static double sample(
    Float32List grid,
    int cols,
    int rows,
    double x,
    double y,
    double hexSize,
  ) {
    // 1. World to flat-top axial (q, r)
    final (int q, int r) = HexMath.flatWorldToGrid(x, y, hexSize);

    // 2. Axial (q, r) to odd-q offset (col, row)
    // col = q
    // row = r + (q - (q & 1)) ~/ 2
    final int col = q;
    final int row = r + (q - (q & 1)) ~/ 2;

    if (col < 0 || col >= cols || row < 0 || row >= rows) {
      return 0.0;
    }

    return grid[row * cols + col];
  }

  /// Computes the numerical gradient vector `(dx, dy)` and its magnitude at
  /// world position `(x, y)` on a flat-topped hex grid.
  ///
  /// Uses central finite difference over the `sample` function with a small
  /// delta `epsilon` (defaulting to a fraction of the `hexSize`).
  static ({double dx, double dy, double magnitude}) computeGradient(
    Float32List grid,
    int cols,
    int rows,
    double x,
    double y,
    double hexSize, {
    double? epsilon,
  }) {
    // Hex fields are discrete, so a very small epsilon will sample the same hex.
    // Epsilon defaults to the hex size to sample adjacent hexes for finite difference.
    final double eps = epsilon ?? hexSize;

    final double right = sample(grid, cols, rows, x + eps, y, hexSize);
    final double left = sample(grid, cols, rows, x - eps, y, hexSize);
    final double bottom = sample(grid, cols, rows, x, y + eps, hexSize);
    final double top = sample(grid, cols, rows, x, y - eps, hexSize);

    final double dx = (right - left) / (2 * eps);
    final double dy = (bottom - top) / (2 * eps); // +y is down

    final double magSq = dx * dx + dy * dy;
    final double magnitude = magSq > 0 ? math.sqrt(magSq) : 0.0;

    return (dx: dx, dy: dy, magnitude: magnitude);
  }
}
