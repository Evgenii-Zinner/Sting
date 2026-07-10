import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/grid_diffusion.dart';

void main() {
  group('GridDiffusion', () {
    test('creates with correct metadata for rectangular grid', () {
      final grid = GridDiffusion.create(columns: 10, rows: 5, diffusionRate: 0.25);

      expect(grid.columns, 10);
      expect(grid.rows, 5);
      expect(grid.isHexagonal, isFalse);
      expect(grid.diffusionRate, closeTo(0.25, 0.001));
      expect(grid.activeBuffer, 0);
      expect(grid.length, 50);
    });

    test('creates with correct metadata for hexagonal grid', () {
      final grid = GridDiffusion.create(columns: 8, rows: 8, isHexagonal: true, diffusionRate: 0.1);

      expect(grid.columns, 8);
      expect(grid.rows, 8);
      expect(grid.isHexagonal, isTrue);
      expect(grid.diffusionRate, closeTo(0.1, 0.001));
      expect(grid.activeBuffer, 0);
      expect(grid.length, 64);
    });

    test('getValue and setValue operate on active buffer', () {
      final grid = GridDiffusion.create(columns: 4, rows: 4);

      grid.setValue(1, 2, 42.5);
      expect(grid.getValue(1, 2), 42.5);

      // Check 1D index
      final index = 2 * 4 + 1; // row * cols + col
      expect(grid.getValueAt(index), 42.5);
    });

    test('getWriteValue and setWriteValue operate on inactive buffer', () {
      final grid = GridDiffusion.create(columns: 4, rows: 4);

      grid.setWriteValue(3, 1, 99.9);
      expect(grid.getWriteValue(3, 1), closeTo(99.9, 0.001));

      // Original buffer should be untouched
      expect(grid.getValue(3, 1), 0.0);
    });

    test('swapBuffers toggles active and inactive buffers', () {
      final grid = GridDiffusion.create(columns: 4, rows: 4);

      grid.setValue(0, 0, 10.0);
      grid.setWriteValue(0, 0, 20.0);

      expect(grid.getValue(0, 0), 10.0);
      expect(grid.getWriteValue(0, 0), 20.0);
      expect(grid.activeBuffer, 0);

      grid.swapBuffers();

      expect(grid.getValue(0, 0), 20.0);
      expect(grid.getWriteValue(0, 0), 10.0);
      expect(grid.activeBuffer, 1);

      grid.swapBuffers();

      expect(grid.getValue(0, 0), 10.0);
      expect(grid.activeBuffer, 0);
    });

    test('out of bounds reads return 0.0', () {
      final grid = GridDiffusion.create(columns: 4, rows: 4);
      grid.setValue(0, 0, 5.0);

      expect(grid.getValue(-1, 0), 0.0);
      expect(grid.getValue(4, 0), 0.0);
      expect(grid.getValue(0, -1), 0.0);
      expect(grid.getValue(0, 4), 0.0);
    });
  });
}
