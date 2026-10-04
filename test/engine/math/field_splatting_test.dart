import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/field_splatting.dart'; // We assume sting is the package name

void main() {
  group('FieldSplatting.splatBilinear', () {
    test('Splats inside grid (energy conservation)', () {
      final grid = Float32List(4 * 4); // 4x4 grid

      // Center at 1.5, 1.5 should distribute 0.25 to each of the 4 surrounding cells
      FieldSplatting.splatBilinear(grid, 4, 4, 1.5, 1.5, 10.0);

      expect(grid[1 * 4 + 1], closeTo(2.5, 0.001));
      expect(grid[1 * 4 + 2], closeTo(2.5, 0.001));
      expect(grid[2 * 4 + 1], closeTo(2.5, 0.001));
      expect(grid[2 * 4 + 2], closeTo(2.5, 0.001));

      // Other cells should be zero
      expect(grid[0], 0.0);

      // Total sum should be 10.0
      final sum = grid.reduce((a, b) => a + b);
      expect(sum, closeTo(10.0, 0.001));
    });

    test('Splats near edge bounds clipping', () {
      final grid = Float32List(4 * 4); // 4x4 grid

      // At -0.5, -0.5, only (0,0) cell is valid
      // w00 = (1 - 0.5) * (1 - 0.5) = 0.25 for (floor -1, floor -1)
      // w10 = 0.5 * 0.5 = 0.25 for (0, -1)
      // w01 = 0.25 for (-1, 0)
      // w11 = 0.25 for (0, 0) -> this one should be added to (0,0)
      FieldSplatting.splatBilinear(grid, 4, 4, -0.5, -0.5, 10.0);

      expect(grid[0], closeTo(2.5, 0.001)); // Only the 0,0 part applies
      expect(grid[1], 0.0);
      expect(grid[4], 0.0);

      // Top right outside bounds
      FieldSplatting.splatBilinear(grid, 4, 4, 3.5, 3.5, 10.0);
      expect(grid[3 * 4 + 3], closeTo(2.5, 0.001));
    });

    test('Splats with maxCap', () {
      final grid = Float32List(2 * 2);
      // Put some initial value
      grid[0] = 5.0; // 0,0

      // Splat at 0.0, 0.0 -> all amount goes to 0,0
      FieldSplatting.splatBilinear(grid, 2, 2, 0.0, 0.0, 10.0, 12.0);

      // 5.0 + 10.0 = 15.0 -> capped at 12.0
      expect(grid[0], closeTo(12.0, 0.001));

      // If we splat again and the current value is > maxCap, it should remain
      grid[0] = 15.0;
      FieldSplatting.splatBilinear(grid, 2, 2, 0.0, 0.0, 10.0, 12.0);
      expect(grid[0], closeTo(15.0, 0.001)); // doesn't lower it
    });
  });

  group('FieldSplatting.splatRadialGaussian', () {
    test('Splats inside grid with radial falloff', () {
      final grid = Float32List(5 * 5); // 5x5 grid

      // Center at 2.0, 2.0, radius 2.0, peakValue 10.0
      FieldSplatting.splatRadialGaussian(grid, 5, 5, 2.0, 2.0, 2.0, 10.0);

      // Center cell should be peakValue
      expect(grid[2 * 5 + 2], closeTo(10.0, 0.001));

      // Cell at 1,2 (distSq = 1) -> falloff = 1 - (1/4) = 0.75 -> 7.5
      expect(grid[2 * 5 + 1], closeTo(7.5, 0.001));

      // Cell at 0,2 (distSq = 4) -> falloff = 1 - (4/4) = 0 -> 0
      expect(grid[2 * 5 + 0], closeTo(0.0, 0.001));

      // Cell at 1,1 (distSq = 2) -> falloff = 1 - (2/4) = 0.5 -> 5.0
      expect(grid[1 * 5 + 1], closeTo(5.0, 0.001));

      // Cell at 0,0 (distSq = 8 > 4) -> should not be modified
      expect(grid[0], 0.0);
    });

    test('Splats near bounds / outside bounds', () {
      final grid = Float32List(5 * 5); // 5x5 grid

      // Center at -1, -1, radius 2.0. Only covers 0,0 and maybe 1,0 / 0,1
      FieldSplatting.splatRadialGaussian(grid, 5, 5, -1.0, -1.0, 2.0, 10.0);

      // 0,0 is distSq = 1^1 + 1^1 = 2 -> falloff = 1 - 2/4 = 0.5
      expect(grid[0], closeTo(5.0, 0.001));

      // 1,0 is distSq = 2^2 + 1^2 = 5 > 4 (radius 2) -> 0.0
      expect(grid[1], 0.0);

      // 4,4 should be zero
      expect(grid[4 * 5 + 4], 0.0);

      // Center way outside
      FieldSplatting.splatRadialGaussian(grid, 5, 5, 10.0, 10.0, 2.0, 10.0);

      // Should not have modified 4,4 since minX = 8, clamped to 4, but dy is checked
      expect(grid[4 * 5 + 4], 0.0);
    });

    test('Negative radius', () {
      final grid = Float32List(5 * 5); // 5x5 grid
      FieldSplatting.splatRadialGaussian(grid, 5, 5, 2.0, 2.0, -1.0, 10.0);
      // No crash, grid unaltered
      expect(grid[0], 0.0);
    });

    test('Splats with maxCap', () {
      final grid = Float32List(3 * 3);
      grid[1 * 3 + 1] = 5.0; // center

      // Splat with maxCap
      FieldSplatting.splatRadialGaussian(grid, 3, 3, 1.0, 1.0, 1.0, 10.0, 12.0);

      // 5.0 + 10.0 = 15.0 -> capped to 12.0
      expect(grid[1 * 3 + 1], closeTo(12.0, 0.001));

      // Splat again on top of a value > maxCap
      grid[1 * 3 + 1] = 15.0;
      FieldSplatting.splatRadialGaussian(grid, 3, 3, 1.0, 1.0, 1.0, 10.0, 12.0);
      expect(grid[1 * 3 + 1], closeTo(15.0, 0.001)); // Should not lower
    });
  });
}
