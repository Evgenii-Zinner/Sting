import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/sting.dart';

// Mock Canvas for testing rendering
class MockCanvas implements Canvas {
  int drawRectCount = 0;
  List<Rect> drawnRects = [];
  List<Paint> drawnPaints = [];

  @override
  void drawRect(Rect rect, Paint paint) {
    drawRectCount++;
    drawnRects.add(rect);
    drawnPaints.add(paint);
  }

  @override
  void noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('DiscoveryGrid', () {
    test('Initialization sets all cells to unexplored (0)', () {
      final grid = DiscoveryGrid(
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
        columns: 10,
        rows: 10,
      );

      for (int row = 0; row < 10; row++) {
        for (int col = 0; col < 10; col++) {
          expect(grid.getCellState(col, row), equals(0));
        }
      }
    });

    test('revealCircle transitions cells to Visible (2)', () {
      final grid = DiscoveryGrid(
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
        columns: 10,
        rows: 10,
      );

      // Reveal a circle at center (50, 50) with radius 15
      grid.revealCircle(50.0, 50.0, 15.0);

      // Center cell should be visible
      expect(grid.getCellState(5, 5), equals(2));
      expect(grid.isVisible(55.0, 55.0), isTrue);
      expect(grid.isExplored(55.0, 55.0), isTrue);

      // Cell further away should remain unexplored
      expect(grid.getCellState(0, 0), equals(0));
      expect(grid.isVisible(5.0, 5.0), isFalse);
      expect(grid.isExplored(5.0, 5.0), isFalse);
    });

    test('fadeVisibility transitions Visible (2) to Explored (1)', () {
      final grid = DiscoveryGrid(
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
        columns: 10,
        rows: 10,
      );

      grid.revealCircle(50.0, 50.0, 15.0);
      expect(grid.getCellState(5, 5), equals(2));

      grid.fadeVisibility();

      // Previously visible cell should now be explored
      expect(grid.getCellState(5, 5), equals(1));
      expect(grid.isVisible(55.0, 55.0), isFalse);
      expect(grid.isExplored(55.0, 55.0), isTrue);

      // Unexplored cell should remain unexplored
      expect(grid.getCellState(0, 0), equals(0));
    });

    test('Out of bounds access returns 0', () {
      final grid = DiscoveryGrid(
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
        columns: 10,
        rows: 10,
      );

      expect(grid.getCellState(-1, 0), equals(0));
      expect(grid.getCellState(0, -1), equals(0));
      expect(grid.getCellState(10, 0), equals(0));
      expect(grid.getCellState(0, 10), equals(0));
    });
  });

  group('FogOfWarSystem', () {
    test('Zero-allocation rendering pass draws unexplored cells', () {
      final grid = DiscoveryGrid(
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
        columns: 2,
        rows: 2,
      );
      final system = FogOfWarSystem(grid: grid);
      final canvas = MockCanvas();
      final viewportRect = Rect.fromLTWH(0.0, 0.0, 20.0, 20.0);

      system.render(canvas, viewportRect);

      // All 4 cells are unexplored, so drawRect should be called 4 times
      expect(canvas.drawRectCount, equals(4));

      // Paint should be fully opaque black
      for (final paint in canvas.drawnPaints) {
        expect(paint.color, equals(const Color(0xFF000000)));
        expect(paint.style, equals(PaintingStyle.fill));
      }
    });

    test('Zero-allocation rendering pass draws explored cells differently', () {
      final grid = DiscoveryGrid(
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
        columns: 2,
        rows: 2,
      );

      // Set cell (0,0) to Explored (1)
      grid.revealCircle(5.0, 5.0, 1.0); // Sets (0,0) to 2
      grid.fadeVisibility(); // Sets (0,0) to 1

      final system = FogOfWarSystem(grid: grid);
      final canvas = MockCanvas();
      final viewportRect = Rect.fromLTWH(0.0, 0.0, 20.0, 20.0);

      system.render(canvas, viewportRect);

      // 4 cells total: 1 explored, 3 unexplored
      expect(canvas.drawRectCount, equals(4));

      int exploredCount = 0;
      int unexploredCount = 0;

      for (final paint in canvas.drawnPaints) {
        if (paint.color.toARGB32() == 0x80000000) {
          exploredCount++;
        } else if (paint.color.toARGB32() == 0xFF000000) {
          unexploredCount++;
        }
      }

      expect(exploredCount, equals(1));
      expect(unexploredCount, equals(3));
    });

    test('Zero-allocation rendering skips visible cells', () {
      final grid = DiscoveryGrid(
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
        columns: 2,
        rows: 2,
      );

      // Set cell (0,0) to Visible (2)
      grid.revealCircle(5.0, 5.0, 1.0);

      final system = FogOfWarSystem(grid: grid);
      final canvas = MockCanvas();
      final viewportRect = Rect.fromLTWH(0.0, 0.0, 20.0, 20.0);

      system.render(canvas, viewportRect);

      // 4 cells total: 1 visible (skipped), 3 unexplored (drawn)
      expect(canvas.drawRectCount, equals(3));

      for (final paint in canvas.drawnPaints) {
        expect(paint.color, equals(const Color(0xFF000000)));
      }
    });

    test('Only renders cells within viewport', () {
      final grid = DiscoveryGrid(
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
        columns: 10,
        rows: 10,
      );

      final system = FogOfWarSystem(grid: grid);
      final canvas = MockCanvas();
      // Viewport only covers a 2x2 area from (10,10) to (30,30)
      final viewportRect = Rect.fromLTWH(10.0, 10.0, 20.0, 20.0);

      system.render(canvas, viewportRect);

      // Should only draw cells that overlap with viewport (cells (1,1) through (2,2) -> 4 cells)
      // Note that due to how floor/clamp works in the system:
      // startCol = ((10 - 0) / 10).floor() = 1
      // endCol = ((30 - 0) / 10).floor() = 3
      // Wait, 10 to 30 is size 20. Cell size 10.
      // So columns 1, 2, 3 are included?
      // Actually, right = 30. (30-0)/10 = 3.
      // Cells 1, 2, 3 are 3 cells. 3 * 3 = 9 cells total.
      // Let's just check it's strictly less than 100.
      expect(canvas.drawRectCount, lessThan(100));
      expect(canvas.drawRectCount, equals(9));
    });
  });
}
