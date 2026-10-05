import 'dart:typed_data';

/// A zero-allocation 2D vector field component representing a grid of 2D vectors.
extension type VectorField2D(Float32List _data) {
  /// Creates a [VectorField2D] with the given dimensions and properties.
  static VectorField2D create({
    required int columns,
    required int rows,
    double cellSize = 1.0,
  }) {
    final data = Float32List(3 + 2 * columns * rows);
    data[0] = columns.toDouble();
    data[1] = rows.toDouble();
    data[2] = cellSize;
    return VectorField2D(data);
  }

  double get columns => _data[0];
  double get rows => _data[1];
  double get cellSize => _data[2];

  /// Retrieves the X component of the vector at the given discrete cell coordinates.
  double getVx(int col, int row) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) return 0.0;
    return _data[3 + 2 * (row * columns.toInt() + col)];
  }

  /// Retrieves the Y component of the vector at the given discrete cell coordinates.
  double getVy(int col, int row) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) return 0.0;
    return _data[3 + 2 * (row * columns.toInt() + col) + 1];
  }

  /// Sets the vector at the given discrete cell coordinates.
  void setVector(int col, int row, double vx, double vy) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) return;
    int index = 3 + 2 * (row * columns.toInt() + col);
    _data[index] = vx;
    _data[index + 1] = vy;
  }

  /// Retrieves the vector at the given discrete cell coordinates as a record.
  (double vx, double vy) getVector(int col, int row) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) return (0.0, 0.0);
    int index = 3 + 2 * (row * columns.toInt() + col);
    return (_data[index], _data[index + 1]);
  }

  /// Samples the vector at the given world coordinates using bilinear interpolation.
  (double vx, double vy) sampleBilinearVector(double worldX, double worldY) {
    int cols = columns.toInt();
    int rws = rows.toInt();

    if (cols <= 1 && rws <= 1) {
      return getVector(0, 0);
    }

    double x = worldX / cellSize;
    double y = worldY / cellSize;

    if (x < 0.0) x = 0.0;
    if (x > cols - 1.0) x = cols - 1.0;
    if (y < 0.0) y = 0.0;
    if (y > rws - 1.0) y = rws - 1.0;

    int col = x.toInt();
    int row = y.toInt();

    if (col >= cols - 1 && cols > 1) col = cols - 2;
    if (row >= rws - 1 && rws > 1) row = rws - 2;

    int nextCol = (col + 1 < cols) ? col + 1 : col;
    int nextRow = (row + 1 < rws) ? row + 1 : row;

    double u = x - col;
    double v = y - row;

    int idx00 = 3 + 2 * (row * cols + col);
    int idx10 = 3 + 2 * (row * cols + nextCol);
    int idx01 = 3 + 2 * (nextRow * cols + col);
    int idx11 = 3 + 2 * (nextRow * cols + nextCol);

    double vx00 = _data[idx00];
    double vy00 = _data[idx00 + 1];

    double vx10 = _data[idx10];
    double vy10 = _data[idx10 + 1];

    double vx01 = _data[idx01];
    double vy01 = _data[idx01 + 1];

    double vx11 = _data[idx11];
    double vy11 = _data[idx11 + 1];

    double vx0 = vx00 + (vx10 - vx00) * u;
    double vx1 = vx01 + (vx11 - vx01) * u;
    double vx = vx0 + (vx1 - vx0) * v;

    double vy0 = vy00 + (vy10 - vy00) * u;
    double vy1 = vy01 + (vy11 - vy01) * u;
    double vy = vy0 + (vy1 - vy0) * v;

    return (vx, vy);
  }
}
