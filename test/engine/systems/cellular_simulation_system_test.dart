import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/systems/cellular_simulation_system.dart';

void main() {
  group('CellularSimulationSystem', () {
    late CellularSimulationSystem system;

    setUp(() {
      system = CellularSimulationSystem();
    });

    test('Game of Life - Blinker (Moore)', () {
      final grid = CellularGrid.create(width: 5, height: 5);

      // Setup blinker in the middle (horizontal)
      grid.setValue(1, 2, 1);
      grid.setValue(2, 2, 1);
      grid.setValue(3, 2, 1);

      // LUT for Game of Life:
      // index = (currentState * 9) + activeNeighbors
      // currentState 0: 0, 1, 2 = 0; 3 = 1; 4, 5, 6, 7, 8 = 0
      // currentState 1: 0, 1 = 0; 2, 3 = 1; 4, 5, 6, 7, 8 = 0
      final lut = Uint8List(18);
      lut[3] = 1; // 0 state + 3 neighbors = alive
      lut[9 + 2] = 1; // 1 state + 2 neighbors = alive
      lut[9 + 3] = 1; // 1 state + 3 neighbors = alive

      system.stepGrid(grid.data, lut, moore: true);

      // Check for vertical blinker
      expect(grid.getValue(2, 1), 1);
      expect(grid.getValue(2, 2), 1);
      expect(grid.getValue(2, 3), 1);

      // Others should be 0
      expect(grid.getValue(1, 2), 0);
      expect(grid.getValue(3, 2), 0);

      // Step again to get horizontal blinker back
      system.stepGrid(grid.data, lut, moore: true);

      expect(grid.getValue(1, 2), 1);
      expect(grid.getValue(2, 2), 1);
      expect(grid.getValue(3, 2), 1);
      expect(grid.getValue(2, 1), 0);
      expect(grid.getValue(2, 3), 0);
    });

    test('Game of Life - Glider (Moore)', () {
      final grid = CellularGrid.create(width: 5, height: 5);

      // Setup glider
      // . . . . .
      // . . 1 . .
      // . . . 1 .
      // . 1 1 1 .
      // . . . . .
      grid.setValue(2, 1, 1);
      grid.setValue(3, 2, 1);
      grid.setValue(1, 3, 1);
      grid.setValue(2, 3, 1);
      grid.setValue(3, 3, 1);

      final lut = Uint8List(18);
      lut[3] = 1; // 0 state + 3 neighbors = alive
      lut[9 + 2] = 1; // 1 state + 2 neighbors = alive
      lut[9 + 3] = 1; // 1 state + 3 neighbors = alive

      // Step 4 times to move glider diagonally
      for (int i = 0; i < 4; i++) {
        system.stepGrid(grid.data, lut, moore: true);
      }

      // Note: Glider at bottom right (bounds are solid 0s here)
      // . . . . .
      // . . . . .
      // . . . 1 .
      // . . . . 1 (cut off by bounds in small grid, actually 0 at boundary)
      // But let's check one step instead.

      final grid2 = CellularGrid.create(width: 5, height: 5);
      grid2.setValue(2, 1, 1);
      grid2.setValue(3, 2, 1);
      grid2.setValue(1, 3, 1);
      grid2.setValue(2, 3, 1);
      grid2.setValue(3, 3, 1);

      system.stepGrid(grid2.data, lut, moore: true);

      // Step 1 pattern:
      // . . . . .
      // . . . . .
      // . 1 . 1 .
      // . . 1 1 .
      // . . 1 . .
      expect(grid2.getValue(1, 2), 1);
      expect(grid2.getValue(3, 2), 1);
      expect(grid2.getValue(2, 3), 1);
      expect(grid2.getValue(3, 3), 1);
      // expect(grid2.getValue(2, 4), 1); // Boundary is skipped
    });

    test('3-State Solidification (Moore)', () {
      // 0 = empty, 1 = liquid, 2 = solid
      final grid = CellularGrid.create(width: 5, height: 5);

      grid.setValue(2, 2, 1); // Center is liquid

      final lut = Uint8List(27);
      // Rules:
      // 0 state (empty) + >=1 active neighbor (liquid or solid) -> liquid
      lut[1] = 1;
      lut[2] = 1;
      lut[3] = 1;
      lut[4] = 1;
      lut[5] = 1;
      lut[6] = 1;
      lut[7] = 1;
      lut[8] = 1;
      // 1 state (liquid) + >=4 active neighbors -> solid
      lut[9 + 0] = 1;
      lut[9 + 1] = 1;
      lut[9 + 2] = 1;
      lut[9 + 3] = 1;
      lut[9 + 4] = 2;
      lut[9 + 5] = 2;
      lut[9 + 6] = 2;
      lut[9 + 7] = 2;
      lut[9 + 8] = 2;
      // 2 state (solid) -> always solid
      lut[18 + 0] = 2;
      lut[18 + 1] = 2;
      lut[18 + 2] = 2;
      lut[18 + 3] = 2;
      lut[18 + 4] = 2;
      lut[18 + 5] = 2;
      lut[18 + 6] = 2;
      lut[18 + 7] = 2;
      lut[18 + 8] = 2;

      // Step 1: center liquid has 0 active neighbors -> stays liquid. (wait, 0 active neighbors, so it should be liquid!)
      // Actually let's just use grid2
      final grid2 = CellularGrid.create(width: 5, height: 5);
      grid2.setValue(2, 2, 1); // liquid

      // Step 1: center liquid has 0 active neighbors -> stays liquid.
      // Empty neighbors have 1 active neighbor -> turn liquid.
      system.stepGrid(grid2.data, lut, moore: true);

      expect(grid2.getValue(2, 2), 1); // Center
      expect(grid2.getValue(2, 1), 1); // Top
      expect(grid2.getValue(1, 1), 1); // Top-left

      // Step 2: Center now has 8 active neighbors -> turns solid
      system.stepGrid(grid2.data, lut, moore: true);

      expect(grid2.getValue(2, 2), 2); // Center is solid
    });

    test('Von Neumann neighborhood', () {
      final grid = CellularGrid.create(width: 5, height: 5);

      // Cross pattern
      grid.setValue(2, 1, 1);
      grid.setValue(1, 2, 1);
      grid.setValue(2, 2, 1); // Center
      grid.setValue(3, 2, 1);
      grid.setValue(2, 3, 1);

      final lut = Uint8List(18);
      // Just check how many neighbors Center has.
      // With Von Neumann, center has 4 active neighbors.
      // With Moore, center has 4 active neighbors.
      // Let's set up a diagonal to differentiate.
      grid.setValue(1, 1, 1);
      grid.setValue(3, 1, 1);
      grid.setValue(1, 3, 1);
      grid.setValue(3, 3, 1);

      // Now center has 4 von neumann neighbors, but 8 moore neighbors.
      // If von neumann, 4 neighbors. State 1 + 4 = 1.
      // If moore, 8 neighbors. State 1 + 8 = 2 (not defined in typical GoL but we can make up a rule).

      lut[9 + 4] = 1; // 4 neighbors -> state 1
      lut[9 + 8] = 2; // 8 neighbors -> state 2

      system.stepGrid(grid.data, lut, moore: false); // von neumann

      expect(grid.getValue(2, 2), 1); // Uses the 4-neighbor rule

      // Reset and test Moore
      final grid2 = CellularGrid.create(width: 5, height: 5);
      grid2.setValue(2, 1, 1);
      grid2.setValue(1, 2, 1);
      grid2.setValue(2, 2, 1);
      grid2.setValue(3, 2, 1);
      grid2.setValue(2, 3, 1);
      grid2.setValue(1, 1, 1);
      grid2.setValue(3, 1, 1);
      grid2.setValue(1, 3, 1);
      grid2.setValue(3, 3, 1);

      system.stepGrid(grid2.data, lut, moore: true); // moore

      expect(grid2.getValue(2, 2), 2); // Uses the 8-neighbor rule
    });

    test('Skips tiny grid', () {
      final grid = CellularGrid.create(width: 2, height: 2);
      final lut = Uint8List(18);

      grid.setValue(0, 0, 1);

      system.stepGrid(grid.data, lut);

      expect(grid.getValue(0, 0), 1); // No change because w < 3
    });
  });
}
