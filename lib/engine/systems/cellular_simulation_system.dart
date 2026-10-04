import 'dart:typed_data';

/// A flat CellularGrid component using a Dart extension type over Uint8List.
/// Memory layout:
/// - Index 0-1: width (16-bit unsigned, little-endian)
/// - Index 2-3: height (16-bit unsigned, little-endian)
/// - Index 4: activeBuffer (0 for Buffer A, 1 for Buffer B)
/// - Index 5 to 4+N: Buffer A (N = width * height)
/// - Index 5+N to 4+2N: Buffer B
extension type CellularGrid(Uint8List data) {
  /// Creates a new CellularGrid component.
  CellularGrid.create({
    required int width,
    required int height,
  }) : this(Uint8List(5 + 2 * (width * height))
          ..[0] = width & 0xFF
          ..[1] = (width >> 8) & 0xFF
          ..[2] = height & 0xFF
          ..[3] = (height >> 8) & 0xFF
          ..[4] = 0); // activeBuffer

  /// The number of columns in the grid.
  int get width => data[0] | (data[1] << 8);

  /// The number of rows in the grid.
  int get height => data[2] | (data[3] << 8);

  /// Gets the currently active buffer (0 for A, 1 for B).
  int get activeBuffer => data[4];

  /// Gets the total number of cells in the grid.
  int get length => width * height;

  /// Gets the offset in the `data` array for the given buffer (0 or 1).
  int getBufferOffset(int bufferIndex) {
    return 5 + bufferIndex * length;
  }

  /// Gets the value at the specified column and row in the currently *active* buffer.
  int getValue(int col, int row) {
    if (col < 0 || col >= width || row < 0 || row >= height) {
      return 0;
    }
    return data[getBufferOffset(activeBuffer) + row * width + col];
  }

  /// Sets the value at the specified column and row in the currently *active* buffer.
  void setValue(int col, int row, int value) {
    if (col < 0 || col >= width || row < 0 || row >= height) {
      return;
    }
    data[getBufferOffset(activeBuffer) + row * width + col] = value;
  }

  /// Swaps the active buffer, making the previously written data the active state.
  void swapBuffers() {
    data[4] = 1 - activeBuffer;
  }
}

/// A system that executes discrete steps of a cellular automaton over a grid.
class CellularSimulationSystem {
  /// Executes a single discrete step on the given grid data.
  ///
  /// [gridData] contains the grid state (using [CellularGrid] layout).
  /// [lut] is a lookup table where index = (currentState * 9) + activeNeighbors.
  /// [moore] determines if the neighborhood is 8-way (true) or 4-way (false).
  /// Iterates all internal cells, counts active neighbors, looks up new state in LUT,
  /// writes to inactive buffer, and swaps buffers.
  void stepGrid(Uint8List gridData, Uint8List lut, {bool moore = true}) {
    final grid = CellularGrid(gridData);
    final int w = grid.width;
    final int h = grid.height;

    // Safety check for invalid grids (smaller than 3x3)
    if (w < 3 || h < 3) return;

    final int activeOffset = grid.getBufferOffset(grid.activeBuffer);
    final int inactiveOffset = grid.getBufferOffset(1 - grid.activeBuffer);

    // Copy top and bottom rows unchanged
    gridData.setRange(inactiveOffset, inactiveOffset + w, gridData, activeOffset);
    gridData.setRange(inactiveOffset + (h - 1) * w, inactiveOffset + h * w, gridData, activeOffset + (h - 1) * w);

    // Iterate internal cells to avoid boundary checking
    for (int r = 1; r < h - 1; r++) {
      int rowOffset = activeOffset + r * w;
      int writeRowOffset = inactiveOffset + r * w;

      // Copy left and right boundaries unchanged
      gridData[writeRowOffset] = gridData[rowOffset];
      gridData[writeRowOffset + w - 1] = gridData[rowOffset + w - 1];

      for (int c = 1; c < w - 1; c++) {
        final int index = rowOffset + c;
        final int currentState = gridData[index];

        int activeNeighbors = 0;

        if (moore) {
          // 8-way neighborhood
          if (gridData[index - w - 1] > 0) activeNeighbors++;
          if (gridData[index - w] > 0) activeNeighbors++;
          if (gridData[index - w + 1] > 0) activeNeighbors++;
          if (gridData[index - 1] > 0) activeNeighbors++;
          if (gridData[index + 1] > 0) activeNeighbors++;
          if (gridData[index + w - 1] > 0) activeNeighbors++;
          if (gridData[index + w] > 0) activeNeighbors++;
          if (gridData[index + w + 1] > 0) activeNeighbors++;
        } else {
          // 4-way neighborhood (von Neumann)
          if (gridData[index - w] > 0) activeNeighbors++;
          if (gridData[index - 1] > 0) activeNeighbors++;
          if (gridData[index + 1] > 0) activeNeighbors++;
          if (gridData[index + w] > 0) activeNeighbors++;
        }

        final int lutIndex = (currentState * 9) + activeNeighbors;
        final int nextState = lutIndex < lut.length ? lut[lutIndex] : currentState;

        gridData[writeRowOffset + c] = nextState;
      }
    }

    grid.swapBuffers();
  }
}
