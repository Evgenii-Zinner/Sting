import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/cellular_grid.dart';

void main() {
  group('CellularGrid Component', () {
    test('initialization writes correct header and buffer sizes', () {
      final grid = CellularGrid.create(10, 20, 16);

      // Underlying buffer size should be 8 + 2 * (10 * 20) = 408
      expect(grid.data.length, equals(408));

      expect(grid.cols, equals(10));
      expect(grid.rows, equals(20));
      expect(grid.activeBuffer, equals(0));
      expect(grid.cellSize, equals(16));
    });

    test('state is correctly isolated between active and inactive buffers', () {
      final grid = CellularGrid.create(5, 5, 8);

      grid.setState(2, 2, 1); // write to active buffer
      expect(grid.getState(2, 2), equals(1));
      expect(grid.getNextBufferState(2, 2), equals(0)); // next buffer should be untouched

      grid.setNextBufferState(2, 2, 2); // write to inactive buffer
      expect(grid.getNextBufferState(2, 2), equals(2));
      expect(grid.getState(2, 2), equals(1)); // active buffer should be untouched
    });

    test('swapBuffers toggles active buffer', () {
      final grid = CellularGrid.create(5, 5, 8);

      grid.setState(1, 1, 10);
      grid.setNextBufferState(1, 1, 20);

      expect(grid.activeBuffer, equals(0));
      expect(grid.getState(1, 1), equals(10));

      grid.swapBuffers();

      expect(grid.activeBuffer, equals(1));
      expect(grid.getState(1, 1), equals(20)); // now reads from what was next buffer

      grid.swapBuffers();
      expect(grid.activeBuffer, equals(0));
      expect(grid.getState(1, 1), equals(10));
    });

    test('boundary safety handles out of bounds safely', () {
      final grid = CellularGrid.create(5, 5, 8);

      // Should not throw
      grid.setState(-1, -1, 1);
      grid.setState(5, 5, 1);
      grid.setNextBufferState(-1, -1, 1);
      grid.setNextBufferState(5, 5, 1);

      // Should return 0
      expect(grid.getState(-1, 0), equals(0));
      expect(grid.getState(0, -1), equals(0));
      expect(grid.getState(5, 0), equals(0));
      expect(grid.getState(0, 5), equals(0));

      expect(grid.getNextBufferState(-1, 0), equals(0));
      expect(grid.getNextBufferState(0, -1), equals(0));
      expect(grid.getNextBufferState(5, 0), equals(0));
      expect(grid.getNextBufferState(0, 5), equals(0));
    });

    test('countNeighbors counts correctly for Moore neighborhood', () {
      final grid = CellularGrid.create(3, 3, 10);

      // Setup grid:
      // 1 0 1
      // 0 1 0
      // 1 1 1
      grid.setState(0, 0, 1);
      grid.setState(2, 0, 1);
      grid.setState(1, 1, 1);
      grid.setState(0, 2, 1);
      grid.setState(1, 2, 1);
      grid.setState(2, 2, 1);

      // Center cell (1, 1) should have 5 neighbors with state 1
      expect(grid.countNeighbors(1, 1, 1, moore: true), equals(5));

      // Top left cell (0, 0) should have 1 neighbor with state 1 (which is at 1,1)
      expect(grid.countNeighbors(0, 0, 1, moore: true), equals(1));

      // Middle top cell (1, 0) should have 3 neighbors
      expect(grid.countNeighbors(1, 0, 1, moore: true), equals(3));
    });

    test('countNeighbors counts correctly for Von Neumann neighborhood', () {
      final grid = CellularGrid.create(3, 3, 10);

      // Setup grid:
      // 0 1 0
      // 1 1 1
      // 0 1 0
      grid.setState(1, 0, 1); // top
      grid.setState(0, 1, 1); // left
      grid.setState(1, 1, 1); // center
      grid.setState(2, 1, 1); // right
      grid.setState(1, 2, 1); // bottom

      // Center cell (1, 1) should have 4 neighbors with state 1 in Von Neumann
      expect(grid.countNeighbors(1, 1, 1, moore: false), equals(4));

      // With moore it should be 4 too
      expect(grid.countNeighbors(1, 1, 1, moore: true), equals(4));

      // Now add a corner
      grid.setState(0, 0, 1);

      // Von Neumann should still be 4
      expect(grid.countNeighbors(1, 1, 1, moore: false), equals(4));

      // But Moore should be 5
      expect(grid.countNeighbors(1, 1, 1, moore: true), equals(5));
    });
  });
}
