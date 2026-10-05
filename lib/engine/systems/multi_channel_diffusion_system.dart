import 'dart:typed_data';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';

/// A flat MultiChannelGrid component using a Dart extension type over Float32List.
/// This component represents a grid of float values with multiple channels,
/// designed for complex multi-fluid diffusion simulations.
/// It implements double-buffering inherently to avoid GC allocations during updates.
///
/// Memory layout:
/// - Index 0: columns (float cast from int)
/// - Index 1: rows (float cast from int)
/// - Index 2: channelCount (float cast from int)
/// - Index 3: activeBuffer (0.0 for Buffer A, 1.0 for Buffer B)
/// - Index 4 to 3+C: diffusionRate per channel (C = channelCount)
/// - Index 4+C to 3+2C: decayRate per channel
/// - Index 4+2C to 3+3C: boundaryMode per channel (0.0=Reflection, 1.0=Absorption)
/// - Index 4+3C to 3+3C+N: Buffer A (N = columns * rows * channelCount)
/// - Index 4+3C+N to 3+3C+2N: Buffer B
extension type MultiChannelGrid(Float32List data) {
  /// Creates a new MultiChannelGrid component.
  MultiChannelGrid.create({
    required int columns,
    required int rows,
    required int channelCount,
  }) : this(_createBuffer(columns, rows, channelCount));

  static Float32List _createBuffer(int columns, int rows, int channelCount) {
    final buffer = Float32List(4 + 3 * channelCount + 2 * (columns * rows * channelCount));
    buffer[0] = columns.toDouble();
    buffer[1] = rows.toDouble();
    buffer[2] = channelCount.toDouble();
    buffer[3] = 0.0;

    // initialize defaults
    for (int i = 0; i < channelCount; i++) {
      // diffusionRate
      buffer[4 + i] = 0.5;
      // decayRate
      buffer[4 + channelCount + i] = 0.0;
      // boundaryMode (0.0 = reflection)
      buffer[4 + 2 * channelCount + i] = 0.0;
    }
    return buffer;
  }

  int get columns => data[0].toInt();
  int get rows => data[1].toInt();
  int get channelCount => data[2].toInt();
  int get activeBuffer => data[3].toInt();
  int get length => columns * rows * channelCount;

  int _getChannelOffset(int channel) {
    return channel;
  }

  void setDiffusionRate(int channel, double rate) {
    data[4 + _getChannelOffset(channel)] = rate;
  }

  double getDiffusionRate(int channel) {
    return data[4 + _getChannelOffset(channel)];
  }

  void setDecayRate(int channel, double rate) {
    data[4 + channelCount + _getChannelOffset(channel)] = rate;
  }

  double getDecayRate(int channel) {
    return data[4 + channelCount + _getChannelOffset(channel)];
  }

  void setBoundaryMode(int channel, double mode) {
    data[4 + 2 * channelCount + _getChannelOffset(channel)] = mode;
  }

  double getBoundaryMode(int channel) {
    return data[4 + 2 * channelCount + _getChannelOffset(channel)];
  }

  int _getIndex(int col, int row, int channel) {
    return (row * columns + col) * channelCount + channel;
  }

  int _getBufferOffset(int bufferIndex) {
    return 4 + 3 * channelCount + bufferIndex * length;
  }

  double getValue(int col, int row, int channel) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return 0.0;
    }
    return data[_getBufferOffset(activeBuffer) + _getIndex(col, row, channel)];
  }

  void setValue(int col, int row, int channel, double value) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return;
    }
    data[_getBufferOffset(activeBuffer) + _getIndex(col, row, channel)] = value;
  }

  double getWriteValue(int col, int row, int channel) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return 0.0;
    }
    int inactiveBuffer = 1 - activeBuffer;
    return data[_getBufferOffset(inactiveBuffer) + _getIndex(col, row, channel)];
  }

  void setWriteValue(int col, int row, int channel, double value) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return;
    }
    int inactiveBuffer = 1 - activeBuffer;
    data[_getBufferOffset(inactiveBuffer) + _getIndex(col, row, channel)] = value;
  }

  double getValueAt(int index) {
      return data[_getBufferOffset(activeBuffer) + index];
  }

  void setWriteValueAt(int index, double value) {
      int inactiveBuffer = 1 - activeBuffer;
      data[_getBufferOffset(inactiveBuffer) + index] = value;
  }

  void swapBuffers() {
    data[3] = (1 - activeBuffer).toDouble();
  }
}

/// A system that calculates numerical cellular diffusion over a multi-channel grid.
/// It operates on `MultiChannelGrid` components, calculating 5-point discrete
/// 2D Laplacian diffusion across each channel.
class MultiChannelDiffusionSystem {
  final Query1<MultiChannelGrid> _query;

  MultiChannelDiffusionSystem({
    required ComponentStorage<MultiChannelGrid> gridCaste,
  }) : _query = Query1<MultiChannelGrid>(gridCaste);

  void update() {
    _query.forEach((entity, grid) {
      final int cols = grid.columns;
      final int rows = grid.rows;
      final int channels = grid.channelCount;
      final int inactiveBufferOffset = grid._getBufferOffset(1 - grid.activeBuffer);

      for (int channel = 0; channel < channels; channel++) {
        final double rate = grid.getDiffusionRate(channel);
        final double decay = grid.getDecayRate(channel);
        final double boundaryMode = grid.getBoundaryMode(channel);
        final bool isAbsorption = boundaryMode > 0.5;

        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            final int baseIndex = (r * cols + c) * channels + channel;
            final double cellValue = grid.getValueAt(baseIndex);

            double sumNeighbors = 0.0;
            int validNeighbors = 0;

            // Left
            if (c > 0) {
              sumNeighbors += grid.getValueAt(baseIndex - channels);
              validNeighbors++;
            }
            // Right
            if (c < cols - 1) {
              sumNeighbors += grid.getValueAt(baseIndex + channels);
              validNeighbors++;
            }
            // Up
            if (r > 0) {
              sumNeighbors += grid.getValueAt(baseIndex - cols * channels);
              validNeighbors++;
            }
            // Down
            if (r < rows - 1) {
              sumNeighbors += grid.getValueAt(baseIndex + cols * channels);
              validNeighbors++;
            }

            final int missingNeighbors = 4 - validNeighbors;
            double effectiveSum = sumNeighbors;

            if (!isAbsorption) {
                // Reflection (zero-flux) boundary
                effectiveSum += missingNeighbors * cellValue;
            }

            final double averageNeighbor = effectiveSum / 4.0;
            final double delta = averageNeighbor - cellValue;

            // Diffusion step
            double newValue = cellValue + delta * rate;

            // Decay step
            newValue *= (1.0 - decay);

            grid.data[inactiveBufferOffset + baseIndex] = newValue;
          }
        }
      }

      grid.swapBuffers();
    });
  }
}
