import 'dart:math';
import 'dart:typed_data';

/// A zero-allocation height map component representing a 2D grid of elevation samples.
extension type HeightMap(Float32List _data) {
  /// Creates a [HeightMap] with the given dimensions and default elevation.
  static HeightMap create({
    required int columns,
    required int rows,
    double originX = 0.0,
    double originY = 0.0,
    double cellWidth = 1.0,
    double cellHeight = 1.0,
    double defaultHeight = 0.0,
  }) {
    final data = Float32List(8 + columns * rows);
    data[0] = originX;
    data[1] = originY;
    data[2] = cellWidth;
    data[3] = cellHeight;
    data[4] = columns.toDouble();
    data[5] = rows.toDouble();
    data[6] = defaultHeight; // minHeight
    data[7] = defaultHeight; // maxHeight
    for (int i = 8; i < data.length; i++) {
      data[i] = defaultHeight;
    }
    return HeightMap(data);
  }

  double get originX => _data[0];
  double get originY => _data[1];
  double get cellWidth => _data[2];
  double get cellHeight => _data[3];
  double get columns => _data[4];
  double get rows => _data[5];
  double get minHeight => _data[6];
  double get maxHeight => _data[7];

  set minHeight(double value) => _data[6] = value;
  set maxHeight(double value) => _data[7] = value;

  /// Retrieves the elevation at the given discrete cell coordinates.
  /// Out-of-bounds coordinates are clamped to the nearest edge.
  double getElevationAtCell(int col, int row) {
    if (col < 0) col = 0;
    int cols = columns.toInt();
    if (col >= cols) col = cols - 1;
    if (row < 0) row = 0;
    int rws = rows.toInt();
    if (row >= rws) row = rws - 1;
    return _data[8 + row * cols + col];
  }

  /// Sets the elevation at the given discrete cell coordinates.
  /// If the coordinates are out of bounds, the operation is ignored.
  void setElevationAtCell(int col, int row, double elevation) {
    int cols = columns.toInt();
    int rws = rows.toInt();
    if (col >= 0 && col < cols && row >= 0 && row < rws) {
      _data[8 + row * cols + col] = elevation;
    }
  }

  /// Samples the height at the given world coordinates using bilinear interpolation.
  double sampleHeight(double worldX, double worldY) {
    int cols = columns.toInt();
    int rws = rows.toInt();

    if (cols <= 1 && rws <= 1) {
      return getElevationAtCell(0, 0);
    }

    double x = (worldX - originX) / cellWidth;
    double y = (worldY - originY) / cellHeight;

    if (x < 0.0) x = 0.0;
    if (x > cols - 1.0) x = cols - 1.0;
    if (y < 0.0) y = 0.0;
    if (y > rws - 1.0) y = rws - 1.0;

    int col = x.toInt();
    int row = y.toInt();

    if (col >= cols - 1 && cols > 1) col = cols - 2;
    if (row >= rws - 1 && rws > 1) row = rws - 2;

    double u = x - col;
    double v = y - row;

    double h00 = _data[8 + row * cols + col];
    double h10 = _data[8 + row * cols + (col + 1)];
    double h01 = _data[8 + (row + 1) * cols + col];
    double h11 = _data[8 + (row + 1) * cols + (col + 1)];

    double h0 = h00 + (h10 - h00) * u;
    double h1 = h01 + (h11 - h01) * u;
    return h0 + (h1 - h0) * v;
  }

  /// Samples the gradient (partial derivatives) at the given world coordinates.
  (double, double) sampleGradient(double worldX, double worldY) {
    int cols = columns.toInt();
    int rws = rows.toInt();

    if (cols <= 1 && rws <= 1) {
      return (0.0, 0.0);
    }

    double x = (worldX - originX) / cellWidth;
    double y = (worldY - originY) / cellHeight;

    if (x < 0.0) x = 0.0;
    if (x > cols - 1.0) x = cols - 1.0;
    if (y < 0.0) y = 0.0;
    if (y > rws - 1.0) y = rws - 1.0;

    int col = x.toInt();
    int row = y.toInt();

    if (col >= cols - 1 && cols > 1) col = cols - 2;
    if (row >= rws - 1 && rws > 1) row = rws - 2;

    double u = x - col;
    double v = y - row;

    double h00 = _data[8 + row * cols + col];
    double h10 = _data[8 + row * cols + (col + 1)];
    double h01 = _data[8 + (row + 1) * cols + col];
    double h11 = _data[8 + (row + 1) * cols + (col + 1)];

    double gradX = ((h10 - h00) * (1.0 - v) + (h11 - h01) * v) / cellWidth;
    double gradY = ((h01 - h00) * (1.0 - u) + (h11 - h10) * u) / cellHeight;

    return (gradX, gradY);
  }

  /// Writes the gradient to a pre-allocated Float32List at the given offset.
  void sampleGradientTo(double worldX, double worldY, Float32List outGrad, [int offset = 0]) {
    final (gx, gy) = sampleGradient(worldX, worldY);
    outGrad[offset] = gx;
    outGrad[offset + 1] = gy;
  }

  /// Returns the steepest slope angle in radians.
  double sampleSlopeAngle(double worldX, double worldY) {
    final (gx, gy) = sampleGradient(worldX, worldY);
    return atan(sqrt(gx * gx + gy * gy));
  }

  /// Returns the 3D surface unit normal vector.
  (double, double, double) sampleNormal(double worldX, double worldY) {
    final (gx, gy) = sampleGradient(worldX, worldY);
    double nx = -gx;
    double ny = -gy;
    double nz = 1.0;
    double length = sqrt(nx * nx + ny * ny + nz * nz);
    return (nx / length, ny / length, nz / length);
  }

  /// Populates the height map using a mathematical function based on world coordinates.
  void fillFromFunction(double Function(double worldX, double worldY) heightFunc) {
    int cols = columns.toInt();
    int rws = rows.toInt();
    double oX = originX;
    double oY = originY;
    double cW = cellWidth;
    double cH = cellHeight;

    double minH = double.infinity;
    double maxH = double.negativeInfinity;

    for (int r = 0; r < rws; r++) {
      for (int c = 0; c < cols; c++) {
        double wx = oX + c * cW;
        double wy = oY + r * cH;
        double h = heightFunc(wx, wy);
        _data[8 + r * cols + c] = h;
        if (h < minH) minH = h;
        if (h > maxH) maxH = h;
      }
    }

    if (cols * rws > 0) {
      minHeight = minH;
      maxHeight = maxH;
    }
  }

  /// Recalculates the minHeight and maxHeight properties by iterating over all cells.
  void recalculateMinMax() {
    int len = columns.toInt() * rows.toInt();
    if (len == 0) return;

    double minH = double.infinity;
    double maxH = double.negativeInfinity;

    for (int i = 0; i < len; i++) {
      double h = _data[8 + i];
      if (h < minH) minH = h;
      if (h > maxH) maxH = h;
    }

    minHeight = minH;
    maxHeight = maxH;
  }
}
