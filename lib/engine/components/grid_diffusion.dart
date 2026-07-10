import 'dart:typed_data';

/// A flat GridDiffusion component using a Dart extension type over Float32List.
/// This component represents a grid (rectangular or hexagonal) of float values
/// designed for diffusion simulations (heat, gas, cellular automata).
/// It implements double-buffering inherently to avoid GC allocations during updates.
///
/// Memory layout:
/// - Index 0: columns (float cast from int)
/// - Index 1: rows (float cast from int)
/// - Index 2: isHexagonal (1.0 for true, 0.0 for false)
/// - Index 3: diffusionRate (float, typically between 0.0 and 1.0)
/// - Index 4: activeBuffer (0.0 for Buffer A, 1.0 for Buffer B)
/// - Index 5 to 4+N: Buffer A (N = columns * rows)
/// - Index 5+N to 4+2N: Buffer B
extension type GridDiffusion(Float32List data) {
  /// Creates a new GridDiffusion component.
  ///
  /// The underlying array size will be 5 + 2 * (columns * rows).
  GridDiffusion.create({
    required int columns,
    required int rows,
    bool isHexagonal = false,
    double diffusionRate = 0.5,
  }) : this(Float32List(5 + 2 * (columns * rows))
          ..[0] = columns.toDouble()
          ..[1] = rows.toDouble()
          ..[2] = isHexagonal ? 1.0 : 0.0
          ..[3] = diffusionRate
          ..[4] = 0.0);

  /// The number of columns in the grid.
  int get columns => data[0].toInt();

  /// The number of rows in the grid.
  int get rows => data[1].toInt();

  /// Whether this grid uses hexagonal topology.
  bool get isHexagonal => data[2] > 0.5;

  /// The rate of diffusion.
  double get diffusionRate => data[3];

  /// Sets the diffusion rate.
  set diffusionRate(double value) => data[3] = value;

  /// Gets the currently active buffer (0 for A, 1 for B).
  int get activeBuffer => data[4].toInt();

  /// Gets the total number of cells in the grid.
  int get length => columns * rows;

  /// Calculates the flat index for a given column and row.
  int _getIndex(int col, int row) {
    return row * columns + col;
  }

  /// Gets the offset in the `data` array for the given buffer (0 or 1).
  int _getBufferOffset(int bufferIndex) {
    return 5 + bufferIndex * length;
  }

  /// Gets the value at the specified column and row in the currently *active* buffer.
  double getValue(int col, int row) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return 0.0;
    }
    return data[_getBufferOffset(activeBuffer) + _getIndex(col, row)];
  }

  /// Sets the value at the specified column and row in the currently *active* buffer.
  void setValue(int col, int row, double value) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return;
    }
    data[_getBufferOffset(activeBuffer) + _getIndex(col, row)] = value;
  }

  /// Gets the value at the specified column and row in the currently *inactive* buffer.
  /// This is typically used by systems writing the next simulation step.
  double getWriteValue(int col, int row) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return 0.0;
    }
    int inactiveBuffer = 1 - activeBuffer;
    return data[_getBufferOffset(inactiveBuffer) + _getIndex(col, row)];
  }

  /// Sets the value at the specified column and row in the currently *inactive* buffer.
  /// This is typically used by systems writing the next simulation step.
  void setWriteValue(int col, int row, double value) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return;
    }
    int inactiveBuffer = 1 - activeBuffer;
    data[_getBufferOffset(inactiveBuffer) + _getIndex(col, row)] = value;
  }

  /// Gets a value from the active buffer using 1D index (fast path).
  double getValueAt(int index) {
    return data[_getBufferOffset(activeBuffer) + index];
  }

  /// Sets a value in the active buffer using 1D index (fast path).
  void setValueAt(int index, double value) {
    data[_getBufferOffset(activeBuffer) + index] = value;
  }

  /// Sets a value in the inactive buffer using 1D index (fast path).
  void setWriteValueAt(int index, double value) {
    int inactiveBuffer = 1 - activeBuffer;
    data[_getBufferOffset(inactiveBuffer) + index] = value;
  }

  /// Swaps the active buffer, making the previously written data the active state.
  void swapBuffers() {
    data[4] = (1 - activeBuffer).toDouble();
  }
}
