import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/vector_field_2d.dart';

void main() {
  group('VectorField2D', () {
    test('create initializes with correct dimensions and layout', () {
      final field = VectorField2D.create(columns: 10, rows: 5, cellSize: 2.0);
      expect(field.columns, 10.0);
      expect(field.rows, 5.0);
      expect(field.cellSize, 2.0);

      // Verify bounds checking and defaults
      expect(field.getVx(0, 0), 0.0);
      expect(field.getVy(0, 0), 0.0);
      expect(field.getVector(0, 0), (0.0, 0.0));

      expect(field.getVx(-1, 0), 0.0);
      expect(field.getVy(-1, 0), 0.0);
      expect(field.getVector(-1, 0), (0.0, 0.0));

      expect(field.getVx(10, 0), 0.0);
      expect(field.getVy(10, 0), 0.0);
      expect(field.getVector(10, 0), (0.0, 0.0));

      expect(field.getVx(0, 5), 0.0);
      expect(field.getVy(0, 5), 0.0);
      expect(field.getVector(0, 5), (0.0, 0.0));
    });

    test('setVector, getVx, getVy, and getVector work correctly', () {
      final field = VectorField2D.create(columns: 2, rows: 2, cellSize: 1.0);
      field.setVector(0, 0, 1.0, 2.0);
      field.setVector(1, 0, -3.0, 4.0);
      field.setVector(0, 1, 5.0, -6.0);
      field.setVector(1, 1, 7.0, 8.0);

      expect(field.getVx(0, 0), 1.0);
      expect(field.getVy(0, 0), 2.0);
      expect(field.getVector(0, 0), (1.0, 2.0));

      expect(field.getVx(1, 0), -3.0);
      expect(field.getVy(1, 0), 4.0);
      expect(field.getVector(1, 0), (-3.0, 4.0));

      expect(field.getVx(0, 1), 5.0);
      expect(field.getVy(0, 1), -6.0);
      expect(field.getVector(0, 1), (5.0, -6.0));

      expect(field.getVx(1, 1), 7.0);
      expect(field.getVy(1, 1), 8.0);
      expect(field.getVector(1, 1), (7.0, 8.0));

      // out of bounds setVector should be a no-op
      field.setVector(-1, 0, 100.0, 100.0);
      expect(field.getVector(-1, 0), (0.0, 0.0));
    });

    test('sampleBilinearVector works correctly for small grids', () {
      final field = VectorField2D.create(columns: 1, rows: 1, cellSize: 10.0);
      field.setVector(0, 0, 5.0, -5.0);
      expect(field.sampleBilinearVector(5.0, 5.0), (5.0, -5.0));
    });

    test('sampleBilinearVector works correctly with interpolation', () {
      final field = VectorField2D.create(columns: 2, rows: 2, cellSize: 10.0);

      // Grid corners (0,0) to (1,1)
      field.setVector(0, 0, 0.0, 0.0);
      field.setVector(1, 0, 10.0, 0.0);
      field.setVector(0, 1, 0.0, 10.0);
      field.setVector(1, 1, 10.0, 10.0);

      // Exact grid points
      var sample = field.sampleBilinearVector(0.0, 0.0);
      expect(sample.$1, closeTo(0.0, 0.0001));
      expect(sample.$2, closeTo(0.0, 0.0001));

      sample = field.sampleBilinearVector(10.0, 0.0);
      expect(sample.$1, closeTo(10.0, 0.0001));
      expect(sample.$2, closeTo(0.0, 0.0001));

      sample = field.sampleBilinearVector(0.0, 10.0);
      expect(sample.$1, closeTo(0.0, 0.0001));
      expect(sample.$2, closeTo(10.0, 0.0001));

      sample = field.sampleBilinearVector(10.0, 10.0);
      expect(sample.$1, closeTo(10.0, 0.0001));
      expect(sample.$2, closeTo(10.0, 0.0001));

      // Interpolated points
      sample = field.sampleBilinearVector(5.0, 0.0); // Halfway between (0,0) and (1,0)
      expect(sample.$1, closeTo(5.0, 0.0001));
      expect(sample.$2, closeTo(0.0, 0.0001));

      sample = field.sampleBilinearVector(0.0, 5.0); // Halfway between (0,0) and (0,1)
      expect(sample.$1, closeTo(0.0, 0.0001));
      expect(sample.$2, closeTo(5.0, 0.0001));

      sample = field.sampleBilinearVector(5.0, 5.0); // Center
      expect(sample.$1, closeTo(5.0, 0.0001));
      expect(sample.$2, closeTo(5.0, 0.0001));
    });

    test('sampleBilinearVector clamps out-of-bounds coordinates', () {
      final field = VectorField2D.create(columns: 2, rows: 2, cellSize: 10.0);

      field.setVector(0, 0, 1.0, 1.0);
      field.setVector(1, 0, 2.0, 2.0);
      field.setVector(0, 1, 3.0, 3.0);
      field.setVector(1, 1, 4.0, 4.0);

      // Way off top-left
      var sample = field.sampleBilinearVector(-50.0, -50.0);
      expect(sample.$1, closeTo(1.0, 0.0001));
      expect(sample.$2, closeTo(1.0, 0.0001));

      // Way off bottom-right
      sample = field.sampleBilinearVector(150.0, 150.0);
      expect(sample.$1, closeTo(4.0, 0.0001));
      expect(sample.$2, closeTo(4.0, 0.0001));

      // Way off top-right
      sample = field.sampleBilinearVector(150.0, -50.0);
      expect(sample.$1, closeTo(2.0, 0.0001));
      expect(sample.$2, closeTo(2.0, 0.0001));

      // Way off bottom-left
      sample = field.sampleBilinearVector(-50.0, 150.0);
      expect(sample.$1, closeTo(3.0, 0.0001));
      expect(sample.$2, closeTo(3.0, 0.0001));
    });

    test('sampleBilinearVector works correctly for 1xN grids', () {
      final field = VectorField2D.create(columns: 1, rows: 2, cellSize: 10.0);
      field.setVector(0, 0, 1.0, 1.0);
      field.setVector(0, 1, 2.0, 2.0);

      var sample = field.sampleBilinearVector(5.0, 5.0);
      expect(sample.$1, closeTo(1.5, 0.0001));
      expect(sample.$2, closeTo(1.5, 0.0001));
    });

    test('sampleBilinearVector works correctly for Nx1 grids', () {
      final field = VectorField2D.create(columns: 2, rows: 1, cellSize: 10.0);
      field.setVector(0, 0, 1.0, 1.0);
      field.setVector(1, 0, 2.0, 2.0);

      var sample = field.sampleBilinearVector(5.0, 5.0);
      expect(sample.$1, closeTo(1.5, 0.0001));
      expect(sample.$2, closeTo(1.5, 0.0001));
    });
  });
}
