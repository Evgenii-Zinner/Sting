import 'dart:typed_data';

/// A Cellular Automata Grid component using a Dart extension type over a Uint8List.
/// Double-buffered flat array to compute cell state transitions without allocating memory.
///
/// Memory layout (first 8 bytes Header):
/// - Index 0-1: cols (Uint16, little endian)
/// - Index 2-3: rows (Uint16, little endian)
/// - Index 4: activeBuffer (Uint8: 0 or 1)
/// - Index 5: cellSize (Uint8)
/// - Index 6-7: reserved (Uint16)
///
/// Followed by Buffer A (cols * rows bytes) and Buffer B (cols * rows bytes).
extension type CellularGrid(Uint8List data) {
  /// Creates a new double-buffered CellularGrid.
  CellularGrid.create(int cols, int rows, int cellSize)
      : this(Uint8List(8 + 2 * (cols * rows))
          ..[0] = cols & 0xFF
          ..[1] = (cols >> 8) & 0xFF
          ..[2] = rows & 0xFF
          ..[3] = (rows >> 8) & 0xFF
          ..[4] = 0
          ..[5] = cellSize);

  /// Number of columns in the grid.
  int get cols => data[0] | (data[1] << 8);
  set cols(int value) {
    data[0] = value & 0xFF;
    data[1] = (value >> 8) & 0xFF;
  }

  /// Number of rows in the grid.
  int get rows => data[2] | (data[3] << 8);
  set rows(int value) {
    data[2] = value & 0xFF;
    data[3] = (value >> 8) & 0xFF;
  }

  /// The currently active buffer index (0 or 1).
  int get activeBuffer => data[4];
  set activeBuffer(int value) => data[4] = value;

  /// The size of each cell (e.g. for rendering).
  int get cellSize => data[5];
  set cellSize(int value) => data[5] = value;

  /// Calculates the 1D array index for the given [col], [row], and [bufferIndex].
  /// Returns -1 if out of bounds.
  int _toIndex(int col, int row, int bufferIndex) {
    if (col < 0 || col >= cols || row < 0 || row >= rows) return -1;
    final int offset = 8 + bufferIndex * (cols * rows);
    return offset + row * cols + col;
  }

  /// Gets the state of the cell at ([col], [row]) in the active buffer.
  int getState(int col, int row) {
    final idx = _toIndex(col, row, activeBuffer);
    if (idx == -1) return 0;
    return data[idx];
  }

  /// Sets the state of the cell at ([col], [row]) in the active buffer.
  void setState(int col, int row, int state) {
    final idx = _toIndex(col, row, activeBuffer);
    if (idx == -1) return;
    data[idx] = state;
  }

  /// Gets the state of the cell at ([col], [row]) in the inactive (next) buffer.
  int getNextBufferState(int col, int row) {
    final idx = _toIndex(col, row, 1 - activeBuffer);
    if (idx == -1) return 0;
    return data[idx];
  }

  /// Sets the state of the cell at ([col], [row]) in the inactive (next) buffer.
  void setNextBufferState(int col, int row, int state) {
    final idx = _toIndex(col, row, 1 - activeBuffer);
    if (idx == -1) return;
    data[idx] = state;
  }

  /// Flips the active buffer (0 to 1, or 1 to 0) to apply the next generation.
  void swapBuffers() {
    activeBuffer = 1 - activeBuffer;
  }

  /// Counts the neighbors around ([col], [row]) matching [targetState] in the active buffer.
  /// If [moore] is true, checks 8 surrounding cells. Otherwise checks 4 (Von Neumann).
  int countNeighbors(int col, int row, int targetState, {bool moore = true}) {
    int count = 0;
    final currentCols = cols;
    final currentRows = rows;
    final bufferOffset = 8 + activeBuffer * (currentCols * currentRows);

    if (moore) {
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final c = col + dx;
          final r = row + dy;
          if (c >= 0 && c < currentCols && r >= 0 && r < currentRows) {
            if (data[bufferOffset + r * currentCols + c] == targetState) {
              count++;
            }
          }
        }
      }
    } else {
      // Von Neumann (4 directions: up, down, left, right)
      if (row - 1 >= 0) {
        if (data[bufferOffset + (row - 1) * currentCols + col] == targetState)
          count++;
      }
      if (row + 1 < currentRows) {
        if (data[bufferOffset + (row + 1) * currentCols + col] == targetState)
          count++;
      }
      if (col - 1 >= 0) {
        if (data[bufferOffset + row * currentCols + (col - 1)] == targetState)
          count++;
      }
      if (col + 1 < currentCols) {
        if (data[bufferOffset + row * currentCols + (col + 1)] == targetState)
          count++;
      }
    }
    return count;
  }
}
