import 'dart:typed_data';

/// A flat MultiChannelDiffusion component using a Dart extension type over Float32List.
/// This component represents a grid of float values with multiple channels per cell
/// designed for diffusion simulations (heat, gas, cellular automata) requiring multiple states.
/// It implements double-buffering inherently to avoid GC allocations during updates.
///
/// Memory layout:
/// - Index 0: columns (float cast from int)
/// - Index 1: rows (float cast from int)
/// - Index 2: channelCount (float cast from int)
/// - Index 3: activeBuffer (0.0 for Buffer A, 1.0 for Buffer B)
/// - Index 4 to 4+channelCount: diffusion rates for each channel
/// - Index 4+channelCount to 4+channelCount+N: Buffer A (N = columns * rows * channelCount)
/// - Index 4+channelCount+N to 4+channelCount+2N: Buffer B
extension type MultiChannelDiffusion(Float32List data) {
  /// Creates a new MultiChannelDiffusion component.
  ///
  /// The underlying array size will be 4 + channelCount + 2 * (columns * rows * channelCount).
  factory MultiChannelDiffusion.create({
    required int columns,
    required int rows,
    required int channelCount,
    List<double>? diffusionRates,
  }) {
    final list = Float32List(4 + channelCount + 2 * (columns * rows * channelCount));
    list[0] = columns.toDouble();
    list[1] = rows.toDouble();
    list[2] = channelCount.toDouble();
    list[3] = 0.0;

    if (diffusionRates != null) {
      assert(diffusionRates.length == channelCount, 'Must provide diffusion rate for each channel');
      for (int i = 0; i < channelCount; i++) {
        list[4 + i] = diffusionRates[i];
      }
    } else {
      for (int i = 0; i < channelCount; i++) {
        list[4 + i] = 0.5; // Default rate
      }
    }
    return MultiChannelDiffusion(list);
  }

  /// The number of columns in the grid.
  int get columns => data[0].toInt();

  /// The number of rows in the grid.
  int get rows => data[1].toInt();

  /// The number of channels per cell.
  int get channelCount => data[2].toInt();

  /// Gets the currently active buffer (0 for A, 1 for B).
  int get activeBuffer => data[3].toInt();

  /// Gets the total number of cells in the grid.
  int get length => columns * rows;

  /// Gets the diffusion rate for a specific channel.
  double getDiffusionRate(int channel) {
    if (channel < 0 || channel >= channelCount) {
      return 0.0;
    }
    return data[4 + channel];
  }

  /// Sets the diffusion rate for a specific channel.
  void setDiffusionRate(int channel, double rate) {
    if (channel < 0 || channel >= channelCount) {
      return;
    }
    data[4 + channel] = rate;
  }

  /// Calculates the flat index for a given column, row, and channel.
  int _getIndex(int col, int row, int channel) {
    return (row * columns + col) * channelCount + channel;
  }

  /// Gets the offset in the `data` array for the given buffer (0 or 1).
  int _getBufferOffset(int bufferIndex) {
    return 4 + channelCount + bufferIndex * length * channelCount;
  }

  /// Gets the value at the specified column, row, and channel in the currently *active* buffer.
  double getValue(int col, int row, int channel) {
    if (col < 0 || col >= columns || row < 0 || row >= rows || channel < 0 || channel >= channelCount) {
      return 0.0;
    }
    return data[_getBufferOffset(activeBuffer) + _getIndex(col, row, channel)];
  }

  /// Sets the value at the specified column, row, and channel in the currently *inactive* buffer.
  /// Writing to the inactive buffer prevents reading torn state during the current frame's simulation.
  void setValue(int col, int row, int channel, double value) {
    if (col < 0 || col >= columns || row < 0 || row >= rows || channel < 0 || channel >= channelCount) {
      return;
    }
    data[_getBufferOffset(1 - activeBuffer) + _getIndex(col, row, channel)] = value;
  }

  /// Swaps the active buffer, making the previously written data the active state.
  void swapBuffers() {
    data[3] = (1 - activeBuffer).toDouble();
  }
}
