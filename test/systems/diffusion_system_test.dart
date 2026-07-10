import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/grid_diffusion.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/diffusion_system.dart';

void main() {
  group('DiffusionSystem', () {
    late ComponentCaste<GridDiffusion> diffusionCaste;
    late DiffusionSystem system;

    setUp(() {
      diffusionCaste = ComponentCaste<GridDiffusion>(10);
      system = DiffusionSystem(diffusionCaste: diffusionCaste);
    });

    double _calculateTotalMass(GridDiffusion grid) {
      double total = 0.0;
      for (int i = 0; i < grid.length; i++) {
        total += grid.getValueAt(i);
      }
      return total;
    }

    test('rectangular grid diffuses correctly and conserves mass', () {
      final grid = GridDiffusion.create(columns: 3, rows: 3, diffusionRate: 1.0);

      // Setup a hot spot in the center
      // 0 0 0
      // 0 9 0
      // 0 0 0
      grid.setValue(1, 1, 9.0);
      diffusionCaste.add(1, grid);

      final initialMass = _calculateTotalMass(grid);
      expect(initialMass, 9.0);

      system.update();

      // With diffusion rate 1.0, the center should average with its 4 neighbors (which are 0)
      // Center cell calculation: avg(0, 0, 0, 0) = 0.0
      // delta = 0.0 - 9.0 = -9.0
      // new_val = 9.0 + (-9.0) * 1.0 = 0.0

      // Top cell calculation (col 1, row 0): neighbors are (0, 9, 0, out_of_bounds)
      // OOB is adiabatic, so it counts as the cell's own value (0).
      // avg(0, 9, 0, 0) = 2.25
      // delta = 2.25 - 0.0 = 2.25
      // new_val = 0.0 + 2.25 * 1.0 = 2.25

      expect(grid.getValue(1, 1), closeTo(0.0, 0.001), reason: 'Center should diffuse outward completely at rate 1.0');
      expect(grid.getValue(1, 0), closeTo(2.25, 0.001), reason: 'Top neighbor should receive heat');
      expect(grid.getValue(1, 2), closeTo(2.25, 0.001), reason: 'Bottom neighbor should receive heat');
      expect(grid.getValue(0, 1), closeTo(2.25, 0.001), reason: 'Left neighbor should receive heat');
      expect(grid.getValue(2, 1), closeTo(2.25, 0.001), reason: 'Right neighbor should receive heat');

      // Corners should remain 0 after 1 step
      expect(grid.getValue(0, 0), closeTo(0.0, 0.001));

      // Mass conservation check (adiabatic boundary)
      final finalMass = _calculateTotalMass(grid);
      expect(finalMass, closeTo(initialMass, 0.001));
    });

    test('hexagonal grid diffuses correctly and conserves mass', () {
      final grid = GridDiffusion.create(columns: 3, rows: 3, isHexagonal: true, diffusionRate: 1.0);

      // Setup a hot spot in the center
      // Row 0 (even): 0 0 0
      // Row 1 (odd):   0 6 0
      // Row 2 (even): 0 0 0
      grid.setValue(1, 1, 6.0);
      diffusionCaste.add(1, grid);

      final initialMass = _calculateTotalMass(grid);
      expect(initialMass, 6.0);

      system.update();

      // For hex grid, cell (1, 1) has 6 neighbors.
      // Since all 6 neighbors are 0, average is 0.
      // Center cell will become 0.0.
      expect(grid.getValue(1, 1), closeTo(0.0, 0.001));

      // The 6 adjacent cells should each receive 1.0
      // For row 1 (odd), neighbors of (1,1) are:
      // (0,1), (2,1)
      // (0,0), (1,0)
      // (0,2), (1,2)
      expect(grid.getValue(0, 1), closeTo(1.0, 0.001));
      expect(grid.getValue(2, 1), closeTo(1.0, 0.001));
      expect(grid.getValue(0, 0), closeTo(1.0, 0.001));
      expect(grid.getValue(1, 0), closeTo(1.0, 0.001));
      expect(grid.getValue(0, 2), closeTo(1.0, 0.001));
      expect(grid.getValue(1, 2), closeTo(1.0, 0.001));

      // Cells not adjacent should remain 0
      expect(grid.getValue(2, 0), closeTo(0.0, 0.001));
      expect(grid.getValue(2, 2), closeTo(0.0, 0.001));

      // Mass conservation check
      final finalMass = _calculateTotalMass(grid);
      expect(finalMass, closeTo(initialMass, 0.001));
    });

    test('adiabatic boundary works correctly on corners', () {
      final grid = GridDiffusion.create(columns: 2, rows: 2, diffusionRate: 1.0);

      // Hot spot in top-left corner
      // 10 0
      // 0  0
      grid.setValue(0, 0, 10.0);
      diffusionCaste.add(1, grid);

      system.update();

      // For (0,0), it has 2 actual neighbors (0,1) and (1,0).
      // The 2 missing neighbors (out of bounds) are treated as having value 10.0.
      // Effective sum: 0 + 0 + 10 + 10 = 20. Average = 5.0.
      // delta = 5.0 - 10.0 = -5.0. new = 10.0 - 5.0 = 5.0

      expect(grid.getValue(0, 0), closeTo(5.0, 0.001));

      // For (1,0) (right neighbor), it has 3 actual neighbors: (0,0)=10, (1,1)=0, (OOB right, OOB top)
      // OOB is adiabatic -> treated as 0 (the cell's own value).
      // Effective sum: 10 + 0 + 0 + 0 = 10. Average = 2.5
      // delta = 2.5 - 0 = 2.5. new = 0 + 2.5 = 2.5

      expect(grid.getValue(1, 0), closeTo(2.5, 0.001));
      expect(grid.getValue(0, 1), closeTo(2.5, 0.001));

      // Mass conservation check
      final finalMass = _calculateTotalMass(grid);
      expect(finalMass, closeTo(10.0, 0.001));
    });
  });
}
