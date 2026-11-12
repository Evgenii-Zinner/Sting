import 'dart:typed_data';
import 'package:sting/engine/components/cellular_grid.dart';

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
    gridData.setRange(
        inactiveOffset, inactiveOffset + w, gridData, activeOffset);
    gridData.setRange(inactiveOffset + (h - 1) * w, inactiveOffset + h * w,
        gridData, activeOffset + (h - 1) * w);

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
        final int nextState =
            lutIndex < lut.length ? lut[lutIndex] : currentState;

        gridData[writeRowOffset + c] = nextState;
      }
    }

    grid.swapBuffers();
  }
}
