import 'dart:typed_data';

/// A zero-allocation component managing a 2D grid of visibility states for Fog of War.
///
/// States:
/// - 0: Unexplored (black fog)
/// - 1: Explored (seen previously, dimmed fog)
/// - 2: Visible (currently within sensor range)
class DiscoveryGrid {
  final double originX;
  final double originY;
  final double cellSize;
  final int columns;
  final int rows;
  final Uint8List _grid;

  DiscoveryGrid({
    required this.originX,
    required this.originY,
    required this.cellSize,
    required this.columns,
    required this.rows,
  }) : _grid = Uint8List(columns * rows);

  /// Reveals a circle of the grid, setting intersected cells to Visible (2).
  void revealCircle(double worldX, double worldY, double radius) {
    final double radiusSq = radius * radius;
    final int startCol = ((worldX - radius - originX) / cellSize).floor().clamp(0, columns - 1);
    final int endCol = ((worldX + radius - originX) / cellSize).floor().clamp(0, columns - 1);
    final int startRow = ((worldY - radius - originY) / cellSize).floor().clamp(0, rows - 1);
    final int endRow = ((worldY + radius - originY) / cellSize).floor().clamp(0, rows - 1);

    for (int row = startRow; row <= endRow; row++) {
      for (int col = startCol; col <= endCol; col++) {
        final double cellCenterX = originX + (col * cellSize) + (cellSize * 0.5);
        final double cellCenterY = originY + (row * cellSize) + (cellSize * 0.5);

        final double dx = worldX - cellCenterX;
        final double dy = worldY - cellCenterY;

        if (dx * dx + dy * dy <= radiusSq) {
          _grid[row * columns + col] = 2;
        }
      }
    }
  }

  /// Fades Visible (2) cells to Explored (1).
  void fadeVisibility() {
    for (int i = 0; i < _grid.length; i++) {
      if (_grid[i] == 2) {
        _grid[i] = 1;
      }
    }
  }

  /// Returns the state of a cell given its column and row.
  int getCellState(int col, int row) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) return 0;
    return _grid[row * columns + col];
  }

  /// Returns true if the cell containing the world coordinate has been explored (state > 0).
  bool isExplored(double worldX, double worldY) {
    final int col = ((worldX - originX) / cellSize).floor();
    final int row = ((worldY - originY) / cellSize).floor();
    return getCellState(col, row) > 0;
  }

  /// Returns true if the cell containing the world coordinate is currently visible (state == 2).
  bool isVisible(double worldX, double worldY) {
    final int col = ((worldX - originX) / cellSize).floor();
    final int row = ((worldY - originY) / cellSize).floor();
    return getCellState(col, row) == 2;
  }
}
