import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sting/engine/components/grid_diffusion.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';

class _BlockCache {
  static const int blockSize = 8;

  final int cols;
  final int rows;
  final int blocksX;
  final int blocksY;

  /// 0 = active, 1 = uniform, 2 = sleeping (both buffers synced & no cooling change)
  final Uint8List state;
  final Uint8List mode;
  final Float32List uniformVal;

  _BlockCache(this.cols, this.rows)
      : blocksX = (cols + blockSize - 1) >> 3,
        blocksY = (rows + blockSize - 1) >> 3,
        state = Uint8List(((cols + blockSize - 1) >> 3) *
            ((rows + blockSize - 1) >> 3)),
        mode = Uint8List(((cols + blockSize - 1) >> 3) *
            ((rows + blockSize - 1) >> 3)),
        uniformVal = Float32List(((cols + blockSize - 1) >> 3) *
            ((rows + blockSize - 1) >> 3));
}

/// A system that calculates numerical cellular diffusion over a hexagonal grid
/// with ambient cooling dissipation.
///
/// Assumes hexagonal cells stored in axial `(q, r)` coordinates (`c = q`, `r = r`).
/// It operates on [GridDiffusion] components without per-frame GC allocations,
/// utilizing double-buffered state, interior branchless fast-paths, and
/// 8x8 block uniform/sleep skipping for steady-state cold and hot regions.
class HexDiffusionCoolingSystem {
  final Query1<GridDiffusion> _query;
  final double ambientBaseline;
  final double coolingRate;
  final Expando<_BlockCache> _blockCaches = Expando<_BlockCache>();

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
      if (cols <= 0 || rows <= 0) return;

      final double diffRate = grid.diffusionRate;
      final double diffOver6 = diffRate / 6.0;
      final double coolFactor = coolingRate * dt;

      final Float32List data = grid.data;
      final int readBase = grid.activeBufferOffset;
      final int writeBase = grid.inactiveBufferOffset;

      _BlockCache? cache = _blockCaches[data];
      if (cache == null || cache.cols != cols || cache.rows != rows) {
        cache = _BlockCache(cols, rows);
        _blockCaches[data] = cache;
      }

      final int blocksX = cache.blocksX;
      final int blocksY = cache.blocksY;
      final Uint8List state = cache.state;
      final Uint8List mode = cache.mode;
      final Float32List uniformVal = cache.uniformVal;

      // 1. Wake up blocks overlapping any externally dirtied cells (expanded by 1 cell).
      if (grid.hasDirtyBounds) {
        final int minC = math.max(0, grid.dirtyMinCol - 1);
        final int maxC = math.min(cols - 1, grid.dirtyMaxCol + 1);
        final int minR = math.max(0, grid.dirtyMinRow - 1);
        final int maxR = math.min(rows - 1, grid.dirtyMaxRow + 1);

        final int bMinX = minC >> 3;
        final int bMaxX = maxC >> 3;
        final int bMinY = minR >> 3;
        final int bMaxY = maxR >> 3;

        for (int by = bMinY; by <= bMaxY; by++) {
          final int rowOffset = by * blocksX;
          for (int bx = bMinX; bx <= bMaxX; bx++) {
            state[rowOffset + bx] = 0;
          }
        }
        grid.clearDirtyBounds();
      }

      // 2. Determine execution mode per block based on its own and neighbors' uniformity.
      for (int by = 0; by < blocksY; by++) {
        final int nyStart = by > 0 ? by - 1 : 0;
        final int nyEnd = by < blocksY - 1 ? by + 1 : blocksY - 1;
        final int rowOffset = by * blocksX;

        for (int bx = 0; bx < blocksX; bx++) {
          final int bIdx = rowOffset + bx;
          final int s = state[bIdx];
          if (s == 0) {
            mode[bIdx] = 0;
            continue;
          }

          final double bVal = uniformVal[bIdx];
          final int nxStart = bx > 0 ? bx - 1 : 0;
          final int nxEnd = bx < blocksX - 1 ? bx + 1 : blocksX - 1;

          bool canFastPath = true;
          neighborCheck:
          for (int ny = nyStart; ny <= nyEnd; ny++) {
            final int nRowOffset = ny * blocksX;
            for (int nx = nxStart; nx <= nxEnd; nx++) {
              final int nbIdx = nRowOffset + nx;
              if (state[nbIdx] == 0 || uniformVal[nbIdx] != bVal) {
                canFastPath = false;
                break neighborCheck;
              }
            }
          }

          mode[bIdx] = canFastPath ? s : 0;
        }
      }

      // 3. Process each block according to its resolved mode.
      for (int by = 0; by < blocksY; by++) {
        final int rStart = by << 3;
        final int rEnd = math.min(rStart + _BlockCache.blockSize, rows);
        final int bRowOffset = by * blocksX;

        for (int bx = 0; bx < blocksX; bx++) {
          final int bIdx = bRowOffset + bx;
          final int bMode = mode[bIdx];

          final int cStart = bx << 3;
          final int cEnd = math.min(cStart + _BlockCache.blockSize, cols);

          if (bMode >= 1) {
            final double val = uniformVal[bIdx];
            final double coolDelta = (val - ambientBaseline) * coolFactor;

            if (bMode == 2 && coolDelta == 0.0) {
              // Sleeping block: both buffers already match and no net change.
              continue;
            }

            final double newVal = val - coolDelta;
            for (int r = rStart; r < rEnd; r++) {
              final int rowBase = writeBase + r * cols;
              for (int c = cStart; c < cEnd; c++) {
                data[rowBase + c] = newVal;
              }
            }

            uniformVal[bIdx] = newVal;
            state[bIdx] = coolDelta == 0.0 ? 2 : 1;
            continue;
          }

          // Active block: run 6-neighbor axial stencil.
          bool isUniform = true;
          double firstNewVal = 0.0;
          bool hasFirst = false;

          final bool isInterior =
              cStart >= 1 && cEnd <= cols - 1 && rStart >= 1 && rEnd <= rows - 1;

          if (isInterior) {
            for (int r = rStart; r < rEnd; r++) {
              final int rowIdx = r * cols;
              for (int c = cStart; c < cEnd; c++) {
                final int index = rowIdx + c;
                final int rIdx = readBase + index;
                final double cellValue = data[rIdx];

                final double sumNeighbors = data[rIdx + 1] +
                    data[rIdx - cols + 1] +
                    data[rIdx - cols] +
                    data[rIdx - 1] +
                    data[rIdx + cols - 1] +
                    data[rIdx + cols];

                final double diffusionDelta =
                    (sumNeighbors - 6.0 * cellValue) * diffOver6;
                final double coolingDelta =
                    (cellValue - ambientBaseline) * coolFactor;
                final double newValue =
                    cellValue + diffusionDelta - coolingDelta;

                data[writeBase + index] = newValue;

                if (!hasFirst) {
                  firstNewVal = data[writeBase + index];
                  hasFirst = true;
                } else if (data[writeBase + index] != firstNewVal) {
                  isUniform = false;
                }
              }
            }
          } else {
            for (int r = rStart; r < rEnd; r++) {
              final int rowIdx = r * cols;
              for (int c = cStart; c < cEnd; c++) {
                final int index = rowIdx + c;
                final int rIdx = readBase + index;
                final double cellValue = data[rIdx];

                double sumNeighbors = 0.0;
                int validNeighbors = 0;

                // Direction 0: (c + 1, r)
                if (c < cols - 1) {
                  sumNeighbors += data[rIdx + 1];
                  validNeighbors++;
                }
                // Direction 1: (c + 1, r - 1)
                if (c < cols - 1 && r > 0) {
                  sumNeighbors += data[rIdx - cols + 1];
                  validNeighbors++;
                }
                // Direction 2: (c, r - 1)
                if (r > 0) {
                  sumNeighbors += data[rIdx - cols];
                  validNeighbors++;
                }
                // Direction 3: (c - 1, r)
                if (c > 0) {
                  sumNeighbors += data[rIdx - 1];
                  validNeighbors++;
                }
                // Direction 4: (c - 1, r + 1)
                if (c > 0 && r < rows - 1) {
                  sumNeighbors += data[rIdx + cols - 1];
                  validNeighbors++;
                }
                // Direction 5: (c, r + 1)
                if (r < rows - 1) {
                  sumNeighbors += data[rIdx + cols];
                  validNeighbors++;
                }

                final int missingNeighbors = 6 - validNeighbors;
                final double effectiveSum =
                    sumNeighbors + (missingNeighbors * cellValue);
                final double diffusionDelta =
                    (effectiveSum - 6.0 * cellValue) * diffOver6;
                final double coolingDelta =
                    (cellValue - ambientBaseline) * coolFactor;
                final double newValue =
                    cellValue + diffusionDelta - coolingDelta;

                data[writeBase + index] = newValue;

                if (!hasFirst) {
                  firstNewVal = data[writeBase + index];
                  hasFirst = true;
                } else if (data[writeBase + index] != firstNewVal) {
                  isUniform = false;
                }
              }
            }
          }

          if (isUniform && hasFirst) {
            state[bIdx] = 1;
            uniformVal[bIdx] = firstNewVal;
          } else {
            state[bIdx] = 0;
          }
        }
      }

      grid.swapBuffers();
    });
  }
}
