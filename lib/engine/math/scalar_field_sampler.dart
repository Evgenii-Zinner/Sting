import 'dart:typed_data';

class ScalarFieldSampler {
  /// Samples a 2D scalar field with bilinear interpolation.
  ///
  /// [grid] is a flat Float32List representing a 2D grid of size [cols] x [rows].
  /// [x] and [y] are continuous coordinates where (0.0, 0.0) is the center of the top-left cell.
  ///
  /// If [wrap] is true, coordinates will wrap around toroidally.
  /// If [clamp] is true, out-of-bounds coordinates will be clamped to the edges.
  /// Otherwise, [defaultValue] is used for out-of-bounds samples (zero-padding).
  static double sampleBilinear(
    Float32List grid,
    int cols,
    int rows,
    double x,
    double y, {
    bool wrap = false,
    bool clamp = false,
    double defaultValue = 0.0,
  }) {
    int x0 = x.floor();
    int y0 = y.floor();
    int x1 = x0 + 1;
    int y1 = y0 + 1;

    double tx = x - x0;
    double ty = y - y0;

    double c00 = _getVal(grid, cols, rows, x0, y0, wrap, clamp, defaultValue);
    double c10 = _getVal(grid, cols, rows, x1, y0, wrap, clamp, defaultValue);
    double c01 = _getVal(grid, cols, rows, x0, y1, wrap, clamp, defaultValue);
    double c11 = _getVal(grid, cols, rows, x1, y1, wrap, clamp, defaultValue);

    double top = c00 + (c10 - c00) * tx;
    double bottom = c01 + (c11 - c01) * tx;
    return top + (bottom - top) * ty;
  }

  static double _getVal(
    Float32List grid,
    int cols,
    int rows,
    int cx,
    int cy,
    bool wrap,
    bool clamp,
    double defaultValue,
  ) {
    if (wrap) {
      cx = cx % cols;
      cy = cy % rows;
    } else if (clamp) {
      if (cx < 0) cx = 0;
      else if (cx >= cols) cx = cols - 1;
      if (cy < 0) cy = 0;
      else if (cy >= rows) cy = rows - 1;
    } else {
      if (cx < 0 || cx >= cols || cy < 0 || cy >= rows) {
        return defaultValue;
      }
    }
    return grid[cy * cols + cx];
  }
}
