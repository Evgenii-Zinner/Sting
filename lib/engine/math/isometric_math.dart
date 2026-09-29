import 'dart:typed_data';

/// Zero-allocation mathematical utilities for 2D isometric projection.
///
/// Handles both Diamond (standard) and Staggered isometric maps.
/// Outputs are written to pre-allocated [Float32List]s to satisfy
/// strict zero-allocation per-frame constraints.
class IsometricMath {
  /// Converts world coordinates (x, y) to isometric grid coordinates (col, row)
  /// using the Diamond projection method.
  ///
  /// The results are written into [outCoord] at indices 0 (col) and 1 (row).
  static void worldToIsoDiamond(double wx, double wy, double tileWidth, double tileHeight, Float32List outCoord) {
    final double halfWidth = tileWidth * 0.5;
    final double halfHeight = tileHeight * 0.5;

    outCoord[0] = (wx / halfWidth + wy / halfHeight) * 0.5;
    outCoord[1] = (wy / halfHeight - wx / halfWidth) * 0.5;
  }

  /// Converts isometric grid coordinates (col, row) to world coordinates (x, y)
  /// using the Diamond projection method.
  ///
  /// The results are written into [outCoord] at indices 0 (x) and 1 (y).
  static void isoToWorldDiamond(double col, double row, double tileWidth, double tileHeight, Float32List outCoord) {
    final double halfWidth = tileWidth * 0.5;
    final double halfHeight = tileHeight * 0.5;

    outCoord[0] = (col - row) * halfWidth;
    outCoord[1] = (col + row) * halfHeight;
  }

  /// Converts world coordinates (x, y) to isometric grid coordinates (col, row)
  /// using the Staggered projection method (Staggered Y).
  ///
  /// The results are written into [outCoord] at indices 0 (col) and 1 (row).
  static void worldToIsoStaggered(double wx, double wy, double tileWidth, double tileHeight, Float32List outCoord) {
    final double halfWidth = tileWidth * 0.5;
    final double halfHeight = tileHeight * 0.5;

    final double row = wy / halfHeight;
    final double staggerX = row.floor().isOdd ? halfWidth : 0.0;
    final double col = (wx - staggerX) / tileWidth;

    outCoord[0] = col;
    outCoord[1] = row;
  }

  /// Converts isometric grid coordinates (col, row) to world coordinates (x, y)
  /// using the Staggered projection method (Staggered Y).
  ///
  /// The results are written into [outCoord] at indices 0 (x) and 1 (y).
  static void isoToWorldStaggered(double col, double row, double tileWidth, double tileHeight, Float32List outCoord) {
    final double halfWidth = tileWidth * 0.5;
    final double halfHeight = tileHeight * 0.5;

    final double staggerX = row.floor().isOdd ? halfWidth : 0.0;
    outCoord[0] = col * tileWidth + staggerX;
    outCoord[1] = row * halfHeight;
  }

  /// Calculates a depth sort key for isometric rendering based on grid coordinates.
  /// 
  /// In an isometric projection, objects further down the screen (higher Y in world space)
  /// should be rendered on top. For a diamond grid, `col + row` is directly proportional
  /// to the world Y coordinate.
  static double getDepth(double col, double row) {
    return col + row;
  }
}
