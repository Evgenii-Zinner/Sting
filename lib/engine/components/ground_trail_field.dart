import 'dart:typed_data';

/// A zero-allocation ground trail field component representing a 2D grid of values.
extension type GroundTrailField(Float32List _data) {
  /// Creates a [GroundTrailField] with the given dimensions and properties.
  static GroundTrailField create({
    required int columns,
    required int rows,
    double originX = 0.0,
    double originY = 0.0,
    double cellSize = 1.0,
    double decayRate = 0.1,
    double maxIntensity = 100.0,
  }) {
    final data = Float32List(7 + columns * rows);
    data[0] = originX;
    data[1] = originY;
    data[2] = cellSize;
    data[3] = columns.toDouble();
    data[4] = rows.toDouble();
    data[5] = decayRate;
    data[6] = maxIntensity;
    return GroundTrailField(data);
  }

  double get originX => _data[0];
  double get originY => _data[1];
  double get cellSize => _data[2];
  double get columns => _data[3];
  double get rows => _data[4];
  double get decayRate => _data[5];
  double get maxIntensity => _data[6];

  set decayRate(double value) => _data[5] = value;
  set maxIntensity(double value) => _data[6] = value;

  /// Retrieves the value at the given discrete cell coordinates.
  double getValue(int col, int row) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) return 0.0;
    return _data[7 + row * columns.toInt() + col];
  }

  /// Sets the value at the given discrete cell coordinates, clamped to [0.0, maxIntensity].
  void setValue(int col, int row, double value) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) return;
    if (value < 0.0) value = 0.0;
    if (value > maxIntensity) value = maxIntensity;
    _data[7 + row * columns.toInt() + col] = value;
  }

  /// Adds to the value at the given discrete cell coordinates, clamped to [0.0, maxIntensity].
  void addValue(int col, int row, double delta) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) return;
    int index = 7 + row * columns.toInt() + col;
    double value = _data[index] + delta;
    if (value < 0.0) value = 0.0;
    if (value > maxIntensity) value = maxIntensity;
    _data[index] = value;
  }

  /// Samples the value at the given world coordinates using bilinear interpolation.
  double sampleValue(double worldX, double worldY) {
    int cols = columns.toInt();
    int rws = rows.toInt();

    if (cols <= 1 && rws <= 1) {
      return getValue(0, 0);
    }

    double x = (worldX - originX) / cellSize;
    double y = (worldY - originY) / cellSize;

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

    double h00 = _data[7 + row * cols + col];
    double h10 = _data[7 + row * cols + (col + 1)];
    double h01 = _data[7 + (row + 1) * cols + col];
    double h11 = _data[7 + (row + 1) * cols + (col + 1)];

    double h0 = h00 + (h10 - h00) * u;
    double h1 = h01 + (h11 - h01) * u;
    return h0 + (h1 - h0) * v;
  }
}
