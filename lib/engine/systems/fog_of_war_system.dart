import 'dart:ui';

import '../components/discovery_grid.dart';

/// A system that renders the [DiscoveryGrid] to the screen as Fog of War.
class FogOfWarSystem {
  final DiscoveryGrid grid;
  final Paint _unexploredPaint;
  final Paint _exploredPaint;

  /// Creates a [FogOfWarSystem] with the given [DiscoveryGrid].
  /// Pre-allocates Paint objects for zero-allocation rendering per frame.
  FogOfWarSystem({required this.grid})
      : _unexploredPaint = Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.fill,
        _exploredPaint = Paint()
          ..color = const Color(0x80000000)
          ..style = PaintingStyle.fill;

  /// Renders the fog of war overlay to the [canvas] based on the current
  /// state of the [grid].
  ///
  /// Achieves zero allocations per frame by avoiding object creation during the
  /// render pass and utilizing pre-allocated resources.
  void render(Canvas canvas, Rect viewportRect) {
    // Determine the visible grid bounds based on the viewport to avoid rendering
    // off-screen cells.
    final int startCol = ((viewportRect.left - grid.originX) / grid.cellSize)
        .floor()
        .clamp(0, grid.columns - 1);
    final int endCol = ((viewportRect.right - grid.originX) / grid.cellSize)
        .floor()
        .clamp(0, grid.columns - 1);
    final int startRow = ((viewportRect.top - grid.originY) / grid.cellSize)
        .floor()
        .clamp(0, grid.rows - 1);
    final int endRow = ((viewportRect.bottom - grid.originY) / grid.cellSize)
        .floor()
        .clamp(0, grid.rows - 1);

    for (int row = startRow; row <= endRow; row++) {
      for (int col = startCol; col <= endCol; col++) {
        final int state = grid.getCellState(col, row);

        // Skip drawing if the cell is fully visible
        if (state == 2) continue;

        final double x = grid.originX + (col * grid.cellSize);
        final double y = grid.originY + (row * grid.cellSize);

        final Rect cellRect = Rect.fromLTWH(x, y, grid.cellSize, grid.cellSize);

        if (state == 0) {
          canvas.drawRect(cellRect, _unexploredPaint);
        } else if (state == 1) {
          canvas.drawRect(cellRect, _exploredPaint);
        }
      }
    }
  }
}
