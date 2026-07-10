import 'dart:typed_data';

/// Represents a hexagonal tilemap backed by a flat Int32List array.
/// Uses a 1D index mapping for axial coordinates (q, r) offset by the radius.
///
/// Memory layout:
/// - Index 0: radius (int)
/// - Index 1: isFlatTopped (int, 1 = true, 0 = false)
/// - Index 2...N: tile IDs (grid array)
extension type HexTilemap(Int32List data) {
  /// Creates a new HexTilemap component with the specified radius.
  ///
  /// The underlying array size will be `2 + (diameter * diameter)`, where diameter = radius * 2 + 1.
  HexTilemap.create(int radius, int isFlatTopped)
      : this(Int32List(2 + ((radius * 2 + 1) * (radius * 2 + 1)))
          ..[0] = radius
          ..[1] = isFlatTopped);

  /// The radius of the hexagonal grid (number of rings around the center).
  int get radius => data[0];

  /// Whether the hex grid is flat-topped (1) or pointy-topped (0).
  int get isFlatTopped => data[1];

  /// The diameter of the grid in terms of grid cells.
  int get diameter => radius * 2 + 1;

  /// Gets the total number of cells in the allocated grid array.
  int get length => diameter * diameter;

  /// Converts axial (q, r) coordinates to a 1D array index.
  /// Returns -1 if out of bounds.
  int _toIndex(int q, int r) {
    if (q < -radius || q > radius || r < -radius || r > radius) {
      return -1;
    }
    // Offset coordinates by radius to make them non-negative
    final int offsetQ = q + radius;
    final int offsetR = r + radius;
    return 2 + (offsetR * diameter) + offsetQ;
  }

  /// Gets the tile ID at the specified axial coordinates (q, r).
  ///
  /// Returns 0 (or a default invalid value) if out of bounds.
  int getTile(int q, int r) {
    final index = _toIndex(q, r);
    if (index == -1) return 0;
    return data[index];
  }

  /// Sets the tile ID at the specified axial coordinates (q, r).
  void setTile(int q, int r, int tileId) {
    final index = _toIndex(q, r);
    if (index == -1) return;
    data[index] = tileId;
  }
}
