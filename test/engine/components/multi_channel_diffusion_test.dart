import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/multi_channel_diffusion.dart';

void main() {
  group('MultiChannelDiffusion', () {
    test('Initialization sets correct header values and array size', () {
      final diffusion = MultiChannelDiffusion.create(
        columns: 10,
        rows: 5,
        channelCount: 3,
        diffusionRates: [0.1, 0.2, 0.3],
      );

      expect(diffusion.columns, 10);
      expect(diffusion.rows, 5);
      expect(diffusion.channelCount, 3);
      expect(diffusion.length, 50);
      expect(diffusion.activeBuffer, 0);

      expect(diffusion.getDiffusionRate(0), closeTo(0.1, 0.0001));
      expect(diffusion.getDiffusionRate(1), closeTo(0.2, 0.0001));
      expect(diffusion.getDiffusionRate(2), closeTo(0.3, 0.0001));

      // Header length = 4
      // Channel rates = 3
      // Buffer A = 10 * 5 * 3 = 150
      // Buffer B = 10 * 5 * 3 = 150
      // Total = 4 + 3 + 150 + 150 = 307
      expect(diffusion.data.length, 307);
    });

    test('Initialization with default diffusion rates', () {
      final diffusion = MultiChannelDiffusion.create(
        columns: 2,
        rows: 2,
        channelCount: 2,
      );

      expect(diffusion.getDiffusionRate(0), closeTo(0.5, 0.0001));
      expect(diffusion.getDiffusionRate(1), closeTo(0.5, 0.0001));
    });

    test(
        'getValue and setValue operate on correct offset and buffer (double buffered)',
        () {
      final diffusion = MultiChannelDiffusion.create(
        columns: 2,
        rows: 2,
        channelCount: 2,
      );

      // Set value at col=1, row=1, channel=1 to 42.0
      // This should write to the inactive buffer (Buffer B, since active=0)
      diffusion.setValue(1, 1, 1, 42.0);

      // Because it's double buffered, getValue from active buffer should still be 0.0
      expect(diffusion.getValue(1, 1, 1), 0.0);

      // Verify other cells and channels are still 0 in active buffer
      expect(diffusion.getValue(0, 0, 0), 0.0);
      expect(diffusion.getValue(1, 1, 0), 0.0);

      // Verify the value was written to Buffer B in the underlying data array
      // Header (4) + Rates (2) = 6
      // Index = (row * cols + col) * channels + channel
      // Index = (1 * 2 + 1) * 2 + 1 = 3 * 2 + 1 = 7
      // Buffer A offset = 6
      // Buffer B offset = 6 + (2*2*2) = 14
      // Data index = 14 + 7 = 21
      expect(diffusion.data[21], 42.0);

      // After swap, getValue should reflect the new value
      diffusion.swapBuffers();
      expect(diffusion.getValue(1, 1, 1), 42.0);
    });

    test('swapBuffers toggles active buffer', () {
      final diffusion = MultiChannelDiffusion.create(
        columns: 2,
        rows: 2,
        channelCount: 2,
      );

      expect(diffusion.activeBuffer, 0);

      // Write to inactive (B)
      diffusion.setValue(0, 0, 0, 10.0);
      expect(diffusion.getValue(0, 0, 0), 0.0); // active is A, should be empty

      diffusion.swapBuffers();
      expect(diffusion.activeBuffer, 1);

      // Now active is B, should have the written value
      expect(diffusion.getValue(0, 0, 0), 10.0);

      // Write to inactive (A)
      diffusion.setValue(0, 0, 0, 20.0);
      // active is B, still 10.0
      expect(diffusion.getValue(0, 0, 0), 10.0);

      // Swap back to Buffer A
      diffusion.swapBuffers();
      expect(diffusion.activeBuffer, 0);
      expect(diffusion.getValue(0, 0, 0), 20.0);
    });

    test(
        'Bounds validation returns 0.0 on invalid reads and ignores invalid writes',
        () {
      final diffusion = MultiChannelDiffusion.create(
        columns: 5,
        rows: 5,
        channelCount: 2,
      );

      // Invalid col
      expect(diffusion.getValue(-1, 0, 0), 0.0);
      expect(diffusion.getValue(5, 0, 0), 0.0);

      // Invalid row
      expect(diffusion.getValue(0, -1, 0), 0.0);
      expect(diffusion.getValue(0, 5, 0), 0.0);

      // Invalid channel
      expect(diffusion.getValue(0, 0, -1), 0.0);
      expect(diffusion.getValue(0, 0, 2), 0.0);

      // Invalid writes should not throw
      expect(() => diffusion.setValue(-1, 0, 0, 1.0), returnsNormally);
      expect(() => diffusion.setValue(0, 5, 0, 1.0), returnsNormally);
      expect(() => diffusion.setValue(0, 0, 2, 1.0), returnsNormally);

      // Invalid diffusion rate channel
      expect(diffusion.getDiffusionRate(-1), 0.0);
      expect(diffusion.getDiffusionRate(2), 0.0);
      expect(() => diffusion.setDiffusionRate(-1, 0.5), returnsNormally);
    });
  });
}
