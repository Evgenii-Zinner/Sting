import 'package:sting/engine/components/grid_diffusion.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';

/// A system that calculates numerical cellular diffusion over a hexagonal grid
/// with ambient cooling dissipation.
///
/// Assumes flat-topped hexes stored in an odd-q offset layout.
/// It operates on `GridDiffusion` components without per-frame GC allocations,
/// utilizing double-buffered state to compute the next frame.
class HexDiffusionCoolingSystem {
  final Query1<GridDiffusion> _query;
  final double ambientBaseline;
  final double coolingRate;

  /// Creates a HexDiffusionCoolingSystem.
  ///
  /// [ambientBaseline] is the target temperature towards which the grid cools.
  /// [coolingRate] is the rate of heat loss (or gain) per second towards the baseline.
  HexDiffusionCoolingSystem({
    required ComponentStorage<GridDiffusion> diffusionCaste,
    this.ambientBaseline = 0.0,
    this.coolingRate = 0.0,
  }) : _query = Query1<GridDiffusion>(diffusionCaste);

  /// Updates the diffusion state of all applicable entities for a given [dt].
  ///
  /// This performs a single discrete diffusion step.
  void update(double dt) {
    _query.forEach((entity, grid) {
      final int cols = grid.columns;
      final int rows = grid.rows;
      final double diffRate = grid.diffusionRate;

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final int index = r * cols + c;
          final double cellValue = grid.getValueAt(index);

          double sumNeighbors = 0.0;
          int validNeighbors = 0;

          // Flat-topped hexagonal grid assumed to use odd-q offset layout.
          final bool isOddCol = (c & 1) == 1;

          // North
          if (r > 0) {
            sumNeighbors += grid.getValueAt(index - cols);
            validNeighbors++;
          }
          // South
          if (r < rows - 1) {
            sumNeighbors += grid.getValueAt(index + cols);
            validNeighbors++;
          }

          if (isOddCol) {
            // Odd column: neighbors are shifted down (+1 row) relative to even columns.
            // North-West
            if (c > 0) {
              sumNeighbors += grid.getValueAt(index - 1);
              validNeighbors++;
            }
            // South-West
            if (c > 0 && r < rows - 1) {
              sumNeighbors += grid.getValueAt(index + cols - 1);
              validNeighbors++;
            }
            // North-East
            if (c < cols - 1) {
              sumNeighbors += grid.getValueAt(index + 1);
              validNeighbors++;
            }
            // South-East
            if (c < cols - 1 && r < rows - 1) {
              sumNeighbors += grid.getValueAt(index + cols + 1);
              validNeighbors++;
            }
          } else {
            // Even column
            // North-West
            if (c > 0 && r > 0) {
              sumNeighbors += grid.getValueAt(index - cols - 1);
              validNeighbors++;
            }
            // South-West
            if (c > 0) {
              sumNeighbors += grid.getValueAt(index - 1);
              validNeighbors++;
            }
            // North-East
            if (c < cols - 1 && r > 0) {
              sumNeighbors += grid.getValueAt(index - cols + 1);
              validNeighbors++;
            }
            // South-East
            if (c < cols - 1) {
              sumNeighbors += grid.getValueAt(index + 1);
              validNeighbors++;
            }
          }

          // Zero-flux boundary condition
          final int expectedNeighbors = 6;
          final int missingNeighbors = expectedNeighbors - validNeighbors;

          final double effectiveSum =
              sumNeighbors + (missingNeighbors * cellValue);
          final double averageNeighbor = effectiveSum / expectedNeighbors;

          // Thermodynamics update:
          // Delta T = (T_neighbors_avg - T) * diffusionRate - (T - T_ambient) * coolingRate * dt
          final double diffusionDelta = (averageNeighbor - cellValue) * diffRate;
          final double coolingDelta = (cellValue - ambientBaseline) * coolingRate * dt;

          final double newValue = cellValue + diffusionDelta - coolingDelta;

          grid.setWriteValueAt(index, newValue);
        }
      }

      grid.swapBuffers();
    });
  }
}
