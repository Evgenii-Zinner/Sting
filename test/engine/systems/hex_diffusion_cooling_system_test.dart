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

    test('diffuses heat to neighbors (odd-q flat-top layout)', () {
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

      // Neighbors should gain heat.
      // odd-q flat-top layout neighbors of (1, 1) (since 1 is odd col):
      // (1, 0), (1, 2)
      // (0, 1), (0, 2)
      // (2, 1), (2, 2)
      expect(grid.getValue(1, 0), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(1, 2), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(0, 1), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(0, 2), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(2, 1), closeTo(100.0 / 6.0, 0.01));
      expect(grid.getValue(2, 2), closeTo(100.0 / 6.0, 0.01));
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
  });
}
