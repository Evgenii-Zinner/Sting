import 'package:sting/engine/components/grid_diffusion.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';

/// A system that calculates numerical cellular diffusion over a grid.
/// It operates on `GridDiffusion` components, calculating diffusion steps for
/// heat, gas, or other cellular automata without per-frame GC allocations.
class DiffusionSystem {
  final Query1<GridDiffusion> _query;

  /// Creates a DiffusionSystem querying entities with `GridDiffusion`.
  DiffusionSystem({
    required ComponentCaste<GridDiffusion> diffusionCaste,
  }) : _query = Query1<GridDiffusion>(diffusionCaste);

  /// Updates the diffusion state of all applicable entities.
  /// This performs a single discrete diffusion step based on the diffusion rate,
  /// reading from the active buffer and writing to the inactive buffer.
  void update() {
    _query.forEach((entity, grid) {
      final int cols = grid.columns;
      final int rows = grid.rows;
      final double rate = grid.diffusionRate;
      final bool isHex = grid.isHexagonal;

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final int index = r * cols + c;
          final double cellValue = grid.getValueAt(index);

          double sumNeighbors = 0.0;
          int validNeighbors = 0;

          if (isHex) {
            // Hexagonal grid (axial coordinates or offset coordinates)
            // Assuming odd-r offset layout for the grid.
            // Neighbors for (col, row):
            // If row is even: (col-1, row), (col+1, row), (col, row-1), (col+1, row-1), (col, row+1), (col+1, row+1)
            // If row is odd:  (col-1, row), (col+1, row), (col-1, row-1), (col, row-1), (col-1, row+1), (col, row+1)

            final bool isOddRow = (r & 1) == 1;

            // Left
            if (c > 0) {
              sumNeighbors += grid.getValueAt(index - 1);
              validNeighbors++;
            }
            // Right
            if (c < cols - 1) {
              sumNeighbors += grid.getValueAt(index + 1);
              validNeighbors++;
            }

            if (isOddRow) {
              // Top-left
              if (c > 0 && r > 0) {
                sumNeighbors += grid.getValueAt(index - cols - 1);
                validNeighbors++;
              }
              // Top-right
              if (r > 0) {
                sumNeighbors += grid.getValueAt(index - cols);
                validNeighbors++;
              }
              // Bottom-left
              if (c > 0 && r < rows - 1) {
                sumNeighbors += grid.getValueAt(index + cols - 1);
                validNeighbors++;
              }
              // Bottom-right
              if (r < rows - 1) {
                sumNeighbors += grid.getValueAt(index + cols);
                validNeighbors++;
              }
            } else {
              // Even row
              // Top-left
              if (r > 0) {
                sumNeighbors += grid.getValueAt(index - cols);
                validNeighbors++;
              }
              // Top-right
              if (c < cols - 1 && r > 0) {
                sumNeighbors += grid.getValueAt(index - cols + 1);
                validNeighbors++;
              }
              // Bottom-left
              if (r < rows - 1) {
                sumNeighbors += grid.getValueAt(index + cols);
                validNeighbors++;
              }
              // Bottom-right
              if (c < cols - 1 && r < rows - 1) {
                sumNeighbors += grid.getValueAt(index + cols + 1);
                validNeighbors++;
              }
            }
          } else {
            // Rectangular grid (von Neumann neighborhood - up, down, left, right)
            // Left
            if (c > 0) {
              sumNeighbors += grid.getValueAt(index - 1);
              validNeighbors++;
            }
            // Right
            if (c < cols - 1) {
              sumNeighbors += grid.getValueAt(index + 1);
              validNeighbors++;
            }
            // Up
            if (r > 0) {
              sumNeighbors += grid.getValueAt(index - cols);
              validNeighbors++;
            }
            // Down
            if (r < rows - 1) {
              sumNeighbors += grid.getValueAt(index + cols);
              validNeighbors++;
            }
          }

          // Calculate new value (zero-flux / adiabatic boundary handling)
          // We assume neighbors outside the boundary have the same value as the current cell,
          // so there is no net flux across the boundary.
          final int expectedNeighbors = isHex ? 6 : 4;
          final int missingNeighbors = expectedNeighbors - validNeighbors;

          final double effectiveSum = sumNeighbors + (missingNeighbors * cellValue);
          final double averageNeighbor = effectiveSum / expectedNeighbors;

          final double delta = averageNeighbor - cellValue;
          final double newValue = cellValue + delta * rate;

          grid.setWriteValueAt(index, newValue);
        }
      }

      // Swap buffers after computing all cells for this grid
      grid.swapBuffers();
    });
  }
}
