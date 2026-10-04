import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ai/potential_field_solver.dart'; // We should probably import the file directly relative if sting doesn't export it, but wait, the prompt says do NOT modify lib/sting.dart or shared files. I'll import relatively to be safe or use sting package if available.

void main() {
  group('PotentialFieldSolver', () {
    test('solveWavefront - basic propagation', () {
      final solver = PotentialFieldSolver(100);
      final cols = 5;
      final rows = 5;
      final potentialGrid = Float32List(cols * rows);
      final costGrid = Uint8List(cols * rows); // 0 cost

      final goalCells = Int32List.fromList([12]); // center cell (2, 2)

      solver.solveWavefront(potentialGrid, costGrid, cols, rows, goalCells);

      // Goal cell is 0
      expect(potentialGrid[12], 0.0);

      // Adjacent cells (horizontal/vertical) should be 1.0
      expect(potentialGrid[11], closeTo(1.0, 0.001)); // (1, 2)
      expect(potentialGrid[13], closeTo(1.0, 0.001)); // (3, 2)
      expect(potentialGrid[7], closeTo(1.0, 0.001)); // (2, 1)
      expect(potentialGrid[17], closeTo(1.0, 0.001)); // (2, 3)

      // Diagonal cells should be ~1.414
      expect(potentialGrid[6], closeTo(1.414, 0.001)); // (1, 1)
      expect(potentialGrid[8], closeTo(1.414, 0.001)); // (3, 1)
      expect(potentialGrid[16], closeTo(1.414, 0.001)); // (1, 3)
      expect(potentialGrid[18], closeTo(1.414, 0.001)); // (3, 3)
    });

    test('solveWavefront - multi-goal propagation', () {
      final solver = PotentialFieldSolver(100);
      final cols = 5;
      final rows = 1;
      final potentialGrid = Float32List(cols * rows);
      final costGrid = Uint8List(cols * rows);

      final goalCells = Int32List.fromList([0, 4]); // ends

      solver.solveWavefront(potentialGrid, costGrid, cols, rows, goalCells);

      expect(potentialGrid[0], 0.0);
      expect(potentialGrid[1], closeTo(1.0, 0.001));
      expect(potentialGrid[2], closeTo(2.0, 0.001));
      expect(potentialGrid[3], closeTo(1.0, 0.001));
      expect(potentialGrid[4], 0.0);
    });

    test('solveWavefront - obstacle avoidance', () {
      final solver = PotentialFieldSolver(100);
      final cols = 3;
      final rows = 3;
      final potentialGrid = Float32List(cols * rows);
      final costGrid = Uint8List(cols * rows);

      // setup an obstacle at (1, 1) which is index 4
      costGrid[4] = 255;

      final goalCells = Int32List.fromList([0]); // (0, 0)

      solver.solveWavefront(potentialGrid, costGrid, cols, rows, goalCells);

      // The obstacle cell should not be updated from infinity
      expect(potentialGrid[4], greaterThan(9999998.0));

      // To get to (2, 2) from (0, 0) with an obstacle at (1, 1), it must go around
      // path: (0, 0) -> (1, 0) -> (2, 1) -> (2, 2) roughly.
      // let's just check that it's greater than a direct diagonal (1.414 * 2)
      expect(potentialGrid[8], greaterThan(2.8));
    });

    test('deriveFlowVectors - downhill flow', () {
      final solver = PotentialFieldSolver(100);
      final cols = 3;
      final rows = 3;
      final potentialGrid = Float32List(cols * rows);
      final costGrid = Uint8List(cols * rows);

      final goalCells = Int32List.fromList([4]); // center cell (1, 1)

      solver.solveWavefront(potentialGrid, costGrid, cols, rows, goalCells);

      final outVectorGrid = Float32List(cols * rows * 2);
      solver.deriveFlowVectors(potentialGrid, outVectorGrid, cols, rows);

      // For cell (0, 0) which is index 0, gradient should point to (1, 1)
      // dirX = 1, dirY = 1 -> normalized ~ (0.707, 0.707)
      expect(outVectorGrid[0 * 2], closeTo(0.707, 0.01));
      expect(outVectorGrid[0 * 2 + 1], closeTo(0.707, 0.01));

      // For cell (1, 0) which is index 1, gradient should point to (1, 1)
      // dirX = 0, dirY = 1
      expect(outVectorGrid[1 * 2], closeTo(0.0, 0.01));
      expect(outVectorGrid[1 * 2 + 1], closeTo(1.0, 0.01));

      // For center cell (1, 1) which is index 4, gradient is zero
      expect(outVectorGrid[4 * 2], closeTo(0.0, 0.01));
      expect(outVectorGrid[4 * 2 + 1], closeTo(0.0, 0.01));
    });
  });
}
