import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/grid_diffusion.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/hex_diffusion_cooling_system.dart';

void main() {
  group('HexDiffusionCoolingSystem', () {
    late ComponentStorage<GridDiffusion> diffusionStorage;

    setUp(() {
      diffusionStorage = ComponentStorage<GridDiffusion>(10);
    });

    test('diffuses heat to neighbors (axial layout, odd column center)', () {
      final system = HexDiffusionCoolingSystem(
        diffusionCaste: diffusionStorage,
        ambientBaseline: 0.0,
        coolingRate: 0.0,
      );

      final grid = GridDiffusion.create(
        columns: 3,
        rows: 3,
        isHexagonal: true,
        diffusionRate: 1.0,
      );

      // Center cell has heat
      grid.setValue(1, 1, 100.0);
      diffusionStorage.add(0, grid);

      system.update(1.0);

      // After 1 step with diffusionRate 1.0, heat diffuses entirely to neighbors based on equation:
      // avg_neighbors = 100/6 (for the center's neighbors looking at the center)
      // wait, the center looking at empty neighbors: avg_neighbors = 0, delta = -100. new center = 0.
      expect(grid.getValue(1, 1), closeTo(0.0, 0.01));

      // Axial layout neighbors of (1, 1):
      // (1, 0), (1, 2), (0, 1), (0, 2), (2, 0), (2, 1)
      expect(grid.getValue(1, 0), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(1, 2), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(0, 1), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(0, 2), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(2, 0), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(2, 1), closeTo(100.0 / 6.0, 0.01));

      // Diagonal non-neighbor corners (distance 2 in axial space) remain 0.0
      expect(grid.getValue(0, 0), closeTo(0.0, 0.01));
      expect(grid.getValue(2, 2), closeTo(0.0, 0.01));
    });

    test('diffuses heat to neighbors (axial layout, even column center)', () {
      final system = HexDiffusionCoolingSystem(
        diffusionCaste: diffusionStorage,
        ambientBaseline: 0.0,
        coolingRate: 0.0,
      );

      final grid = GridDiffusion.create(
        columns: 5,
        rows: 5,
        isHexagonal: true,
        diffusionRate: 1.0,
      );

      // Even column center (2, 2) has heat
      grid.setValue(2, 2, 100.0);
      diffusionStorage.add(0, grid);

      system.update(1.0);

      expect(grid.getValue(2, 2), closeTo(0.0, 0.01));

      // Axial layout neighbors of (2, 2):
      // (2, 1), (2, 3), (1, 2), (1, 3), (3, 1), (3, 2)
      expect(grid.getValue(2, 1), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(2, 3), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(1, 2), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(1, 3), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(3, 1), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(3, 2), closeTo(100.0 / 6.0, 0.01));

      // Diagonal non-neighbors (distance 2 in axial space) remain 0.0
      expect(grid.getValue(1, 1), closeTo(0.0, 0.01));
      expect(grid.getValue(3, 3), closeTo(0.0, 0.01));
    });

    test('cools down towards ambient baseline', () {
      final system = HexDiffusionCoolingSystem(
        diffusionCaste: diffusionStorage,
        ambientBaseline: 20.0,
        coolingRate: 0.5,
      );

      final grid = GridDiffusion.create(
        columns: 3,
        rows: 3,
        isHexagonal: true,
        diffusionRate: 0.0, // no diffusion
      );

      grid.setValue(1, 1, 100.0);
      diffusionStorage.add(0, grid);

      system.update(1.0);

      // Expected cooling: (100 - 20) * 0.5 * 1.0 = 40.0
      // New value: 100 - 40 = 60
      expect(grid.getValue(1, 1), closeTo(60.0, 0.01));
    });

    test('heats up towards ambient baseline', () {
      final system = HexDiffusionCoolingSystem(
        diffusionCaste: diffusionStorage,
        ambientBaseline: 50.0,
        coolingRate: 0.2,
      );

      final grid = GridDiffusion.create(
        columns: 3,
        rows: 3,
        isHexagonal: true,
        diffusionRate: 0.0,
      );

      grid.setValue(1, 1, 10.0);
      diffusionStorage.add(0, grid);

      system.update(1.0);

      // Expected cooling: (10 - 50) * 0.2 * 1.0 = -8.0
      // New value: 10 - (-8) = 18
      expect(grid.getValue(1, 1), closeTo(18.0, 0.01));
    });

    test('maintains zero-flux boundary conditions', () {
      final system = HexDiffusionCoolingSystem(
        diffusionCaste: diffusionStorage,
        ambientBaseline: 0.0,
        coolingRate: 0.0,
      );

      final grid = GridDiffusion.create(
        columns: 2,
        rows: 2,
        isHexagonal: true,
        diffusionRate: 0.5,
      );

      // Put 100 in top-left
      grid.setValue(0, 0, 100.0);
      diffusionStorage.add(0, grid);

      system.update(1.0);

      // Total heat should remain constant in the system without cooling
      double totalHeat = 0.0;
      for (int r = 0; r < 2; r++) {
        for (int c = 0; c < 2; c++) {
          totalHeat += grid.getValue(c, r);
        }
      }
      expect(totalHeat, closeTo(100.0, 0.01));
    });

    test('block sleep and wake-up matches naive axial stencil over multiple steps',
        () {
      const int cols = 32;
      const int rows = 32;
      const double diffRate = 0.18;
      const double ambient = 0.0;
      const double cooling = 0.0;
      const double dt = 0.016;

      final system = HexDiffusionCoolingSystem(
        diffusionCaste: diffusionStorage,
        ambientBaseline: ambient,
        coolingRate: cooling,
      );

      final grid = GridDiffusion.create(
        columns: cols,
        rows: rows,
        isHexagonal: true,
        diffusionRate: diffRate,
      );
      grid.setValue(4, 4, 100.0);
      diffusionStorage.add(0, grid);

      // Reference float32-compatible double buffer
      var refRead = List<double>.filled(cols * rows, 0.0);
      var refWrite = List<double>.filled(cols * rows, 0.0);
      refRead[4 * cols + 4] = 100.0;

      void stepReference() {
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            final int idx = r * cols + c;
            final double cellValue = refRead[idx];
            double sumNeighbors = 0.0;
            int validNeighbors = 0;
            if (c < cols - 1) {
              sumNeighbors += refRead[idx + 1];
              validNeighbors++;
            }
            if (c < cols - 1 && r > 0) {
              sumNeighbors += refRead[idx - cols + 1];
              validNeighbors++;
            }
            if (r > 0) {
              sumNeighbors += refRead[idx - cols];
              validNeighbors++;
            }
            if (c > 0) {
              sumNeighbors += refRead[idx - 1];
              validNeighbors++;
            }
            if (c > 0 && r < rows - 1) {
              sumNeighbors += refRead[idx + cols - 1];
              validNeighbors++;
            }
            if (r < rows - 1) {
              sumNeighbors += refRead[idx + cols];
              validNeighbors++;
            }
            final double effectiveSum =
                sumNeighbors + (6 - validNeighbors) * cellValue;
            final double avg = effectiveSum / 6.0;
            refWrite[idx] = cellValue +
                (avg - cellValue) * diffRate -
                (cellValue - ambient) * cooling * dt;
          }
        }
        final tmp = refRead;
        refRead = refWrite;
        refWrite = tmp;
      }

      // Run 10 steps (far blocks will sleep by step 3)
      for (int step = 0; step < 10; step++) {
        system.update(dt);
        stepReference();
      }

      // Inject heat into a sleeping block at (24, 24)
      grid.setValue(24, 24, 80.0);
      refRead[24 * cols + 24] = 80.0;

      // Run 10 more steps to verify wake-up and boundary propagation
      for (int step = 0; step < 10; step++) {
        system.update(dt);
        stepReference();
      }

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          expect(grid.getValue(c, r), closeTo(refRead[r * cols + c], 1e-4),
              reason: 'Mismatch at ($c, $r)');
        }
      }
    });

    test('uniform cooling block fast-path matches naive stencil with coolingRate > 0',
        () {
      const int cols = 24;
      const int rows = 24;
      const double diffRate = 0.18;
      const double ambient = 0.0;
      const double cooling = 0.2;
      const double dt = 0.1;

      final system = HexDiffusionCoolingSystem(
        diffusionCaste: diffusionStorage,
        ambientBaseline: ambient,
        coolingRate: cooling,
      );

      final grid = GridDiffusion.create(
        columns: cols,
        rows: rows,
        isHexagonal: true,
        diffusionRate: diffRate,
      );
      for (int i = 0; i < grid.length; i++) {
        grid.setValueAt(i, -25.0);
      }
      diffusionStorage.add(0, grid);

      double expected = -25.0;
      for (int step = 0; step < 5; step++) {
        system.update(dt);
        expected = expected - (expected - ambient) * cooling * dt;
      }

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          expect(grid.getValue(c, r), closeTo(expected, 1e-4));
        }
      }
    });
  });
}
