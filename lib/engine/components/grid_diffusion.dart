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
/// - Index 5: dirtyMinCol (float cast from int)
/// - Index 6: dirtyMaxCol (float cast from int)
/// - Index 7: dirtyMinRow (float cast from int)
/// - Index 8: dirtyMaxRow (float cast from int)
/// - Index 9 to 8+N: Buffer A (N = columns * rows)
/// - Index 9+N to 8+2N: Buffer B
extension type GridDiffusion(Float32List data) {
  static const int _headerSize = 9;

  /// Creates a new GridDiffusion component.
  ///
  /// The underlying array size will be 9 + 2 * (columns * rows).
  GridDiffusion.create({
    required int columns,
    required int rows,
    bool isHexagonal = false,
    double diffusionRate = 0.5,
  }) : this(Float32List(_headerSize + 2 * (columns * rows))
          ..[0] = columns.toDouble()
          ..[1] = rows.toDouble()
          ..[2] = isHexagonal ? 1.0 : 0.0
          ..[3] = diffusionRate
          ..[4] = 0.0
          ..[5] = columns.toDouble()
          ..[6] = -1.0
          ..[7] = rows.toDouble()
          ..[8] = -1.0);

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

  /// The minimum column index dirtied by external writes since last clear.
  int get dirtyMinCol => data[5].toInt();

  /// The maximum column index dirtied by external writes since last clear.
  int get dirtyMaxCol => data[6].toInt();

  /// The minimum row index dirtied by external writes since last clear.
  int get dirtyMinRow => data[7].toInt();

  /// The maximum row index dirtied by external writes since last clear.
  int get dirtyMaxRow => data[8].toInt();

  /// Whether any cells have been dirtied by external writes since last clear.
  bool get hasDirtyBounds => data[6] >= data[5] && data[8] >= data[7];

  /// Resets the dirty bounding box to empty.
  void clearDirtyBounds() {
    data[5] = data[0];
    data[6] = -1.0;
    data[7] = data[1];
    data[8] = -1.0;
  }

  void _markDirty(int col, int row) {
    final double c = col.toDouble();
    final double r = row.toDouble();
    if (c < data[5]) data[5] = c;
    if (c > data[6]) data[6] = c;
    if (r < data[7]) data[7] = r;
    if (r > data[8]) data[8] = r;
  }

  /// Calculates the flat index for a given column and row.
  int _getIndex(int col, int row) {
    return row * columns + col;
  }

  /// Gets the offset in the `data` array for the given buffer (0 or 1).
  int _getBufferOffset(int bufferIndex) {
    return _headerSize + bufferIndex * length;
  }

  /// Gets the buffer offset in `data` for the currently active (read) buffer.
  int get activeBufferOffset => _headerSize + activeBuffer * length;

  /// Gets the buffer offset in `data` for the currently inactive (write) buffer.
  int get inactiveBufferOffset => _headerSize + (1 - activeBuffer) * length;

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
    final int offset = _getBufferOffset(activeBuffer) + _getIndex(col, row);
    if (data[offset] == value) return;
    data[offset] = value;
    _markDirty(col, row);
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
    final int offset = _getBufferOffset(activeBuffer) + index;
    if (data[offset] == value) return;
    data[offset] = value;
    final int cols = columns;
    _markDirty(index % cols, index ~/ cols);
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
