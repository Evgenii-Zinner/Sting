import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/hex_field_sampler.dart';
import 'package:sting/engine/math/hex_math.dart';

void main() {
  group('HexFieldSampler', () {
    late Float32List grid;
    final int cols = 5;
    final int rows = 5;
    final double hexSize = 10.0;

    setUp(() {
      grid = Float32List(cols * rows);
    });

    test('samples center value correctly', () {
      // flatWorldToGrid center logic
      final (x, y) = HexMath.flatGridToWorld(2, 2, hexSize);

      // Map (q: 2, r: 2) to offset:
      // col = 2
      // row = 2 + (2 - 0)/2 = 3
      grid[3 * cols + 2] = 42.0;

      final sampled = HexFieldSampler.sample(grid, cols, rows, x, y, hexSize);
      expect(sampled, 42.0);
    });

    test('returns 0.0 for out of bounds sampling', () {
      final sampled = HexFieldSampler.sample(grid, cols, rows, -100.0, -100.0, hexSize);
      expect(sampled, 0.0);
    });

    test('computes gradient correctly', () {
      final (x, y) = HexMath.flatGridToWorld(2, 2, hexSize);

      // (q: 2, r: 2) -> (col: 2, row: 3)
      grid[3 * cols + 2] = 10.0;

      // Sample slightly right (q: 3, r: 2) -> col: 3, row: 2 + (3-1)/2 = 3
      // Let's just populate a generic gradient

      // Let's create a known gradient on the grid
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          grid[r * cols + c] = c * 10.0 + r * 5.0; // Gradient increases right and down
        }
      }

      final gradient = HexFieldSampler.computeGradient(grid, cols, rows, x, y, hexSize);

      // Expect dx to be positive
      expect(gradient.dx, greaterThan(0.0));
      // Expect dy to be positive
      expect(gradient.dy, greaterThan(0.0));
      expect(gradient.magnitude, greaterThan(0.0));
    });

    test('computes zero gradient in uniform field', () {
      final (x, y) = HexMath.flatGridToWorld(2, 2, hexSize);

      for (int i = 0; i < grid.length; i++) {
        grid[i] = 15.0;
      }

      final gradient = HexFieldSampler.computeGradient(grid, cols, rows, x, y, hexSize);

      expect(gradient.dx, 0.0);
      expect(gradient.dy, 0.0);
      expect(gradient.magnitude, 0.0);
    });
  });
}
