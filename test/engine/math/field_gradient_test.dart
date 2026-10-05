import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/field_gradient.dart'; // We should probably import using package:sting/engine/math/field_gradient.dart? Wait, package name is probably sting.

void main() {
  group('FieldGradient', () {
    test('flat region returns zero gradient', () {
      final cols = 3;
      final rows = 3;
      final grid = Float32List(cols * rows);
      for (int i = 0; i < grid.length; i++) {
        grid[i] = 5.0; // flat field
      }

      final result = FieldGradient.computeGradient(grid, cols, rows, 1.0, 1.0);
      expect(result.dx, closeTo(0.0, 0.0001));
      expect(result.dy, closeTo(0.0, 0.0001));
      expect(result.magnitude, closeTo(0.0, 0.0001));
    });

    test('linear slope constant gradient (x-axis)', () {
      final cols = 4;
      final rows = 4;
      final grid = Float32List(cols * rows);
      // F(x,y) = 2x
      for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
          grid[y * cols + x] = 2.0 * x;
        }
      }

      final result = FieldGradient.computeGradient(grid, cols, rows, 1.5, 1.5,
          epsilon: 0.5);
      expect(result.dx, closeTo(2.0, 0.0001));
      expect(result.dy, closeTo(0.0, 0.0001));
      expect(result.magnitude, closeTo(2.0, 0.0001));
    });

    test('linear slope constant gradient (y-axis)', () {
      final cols = 4;
      final rows = 4;
      final grid = Float32List(cols * rows);
      // F(x,y) = -3y
      for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
          grid[y * cols + x] = -3.0 * y;
        }
      }

      final result = FieldGradient.computeGradient(grid, cols, rows, 1.5, 1.5,
          epsilon: 0.5);
      expect(result.dx, closeTo(0.0, 0.0001));
      expect(result.dy, closeTo(-3.0, 0.0001));
      expect(result.magnitude, closeTo(3.0, 0.0001));
    });

    test('boundary clamping behavior', () {
      final cols = 3;
      final rows = 3;
      final grid = Float32List(cols * rows);
      // F(x,y) = x + y
      for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
          grid[y * cols + x] = (x + y).toDouble();
        }
      }

      // Sample outside the right boundary. The x+epsilon will be clamped to cols-1
      // x=2.5, y=1.0. left=1.5, right=3.5 (clamped to 2).
      // At x=1.5, y=1.0, value is 2.5
      // At x=2.0 (clamped), y=1.0, value is 3.0
      // dx = (3.0 - 2.5) / 2 = 0.25
      final result = FieldGradient.computeGradient(grid, cols, rows, 2.5, 1.0,
          epsilon: 1.0);
      expect(result.dx,
          closeTo(0.25, 0.0001)); // It gets clamped, so gradient is shallower
    });

    test('radial peak (distance field)', () {
      final cols = 5;
      final rows = 5;
      final grid = Float32List(cols * rows);
      // F(x,y) = (x-2)^2 + (y-2)^2
      for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
          grid[y * cols + x] =
              math.pow(x - 2, 2).toDouble() + math.pow(y - 2, 2).toDouble();
        }
      }

      // at (1, 1), center is (2,2). Grad of x^2 + y^2 is 2x, 2y. Here it's 2(x-2), 2(y-2)
      // at (1,1): dx = -2, dy = -2
      final result = FieldGradient.computeGradient(grid, cols, rows, 1.0, 1.0,
          epsilon: 0.5);
      expect(result.dx, closeTo(-2.0, 0.0001));
      expect(result.dy, closeTo(-2.0, 0.0001));
      expect(result.magnitude, closeTo(math.sqrt(8), 0.0001));
    });

    test('saddle point', () {
      final cols = 5;
      final rows = 5;
      final grid = Float32List(cols * rows);
      // F(x,y) = x^2 - y^2
      // center at 2,2 => F(x,y) = (x-2)^2 - (y-2)^2
      for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
          grid[y * cols + x] =
              math.pow(x - 2, 2).toDouble() - math.pow(y - 2, 2).toDouble();
        }
      }

      // Grad = 2(x-2), -2(y-2)
      // at (3, 1), dx = 2(1) = 2, dy = -2(-1) = 2
      final result = FieldGradient.computeGradient(grid, cols, rows, 3.0, 1.0,
          epsilon: 0.5);
      expect(result.dx, closeTo(2.0, 0.0001));
      expect(result.dy, closeTo(2.0, 0.0001));
    });

    test('normalization toggle', () {
      final cols = 4;
      final rows = 4;
      final grid = Float32List(cols * rows);
      // F(x,y) = 3x + 4y
      for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
          grid[y * cols + x] = 3.0 * x + 4.0 * y;
        }
      }

      // Gradient should be (3, 4), magnitude = 5
      final resultUnnormalized = FieldGradient.computeGradient(
          grid, cols, rows, 1.5, 1.5,
          epsilon: 0.5);
      expect(resultUnnormalized.dx, closeTo(3.0, 0.0001));
      expect(resultUnnormalized.dy, closeTo(4.0, 0.0001));
      expect(resultUnnormalized.magnitude, closeTo(5.0, 0.0001));

      // With normalization, dx = 3/5 = 0.6, dy = 4/5 = 0.8
      final resultNormalized = FieldGradient.computeGradient(
          grid, cols, rows, 1.5, 1.5,
          epsilon: 0.5, normalize: true);
      expect(resultNormalized.dx, closeTo(0.6, 0.0001));
      expect(resultNormalized.dy, closeTo(0.8, 0.0001));
      expect(
          resultNormalized.magnitude,
          closeTo(5.0,
              0.0001)); // Note magnitude returned is the original magnitude before normalization
    });

    test('normalization on zero gradient', () {
      final cols = 3;
      final rows = 3;
      final grid = Float32List(cols * rows);
      // F(x,y) = 0
      final resultNormalized = FieldGradient.computeGradient(
          grid, cols, rows, 1.0, 1.0,
          normalize: true);

      expect(resultNormalized.dx, closeTo(0.0, 0.0001));
      expect(resultNormalized.dy, closeTo(0.0, 0.0001));
      expect(resultNormalized.magnitude, closeTo(0.0, 0.0001));
    });
  });
}
