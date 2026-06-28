import 'dart:typed_data';

/// A flat Tilemap component using a Dart extension type over Int32List.
/// This packs the tilemap metadata (dimensions, tile size) and the tile grid
/// into a contiguous chunk of memory to avoid GC allocations.
///
/// Memory layout:
/// - Index 0: columns (int)
/// - Index 1: rows (int)
/// - Index 2: tileWidth (int)
/// - Index 3: tileHeight (int)
/// - Index 4...N: tile IDs (grid array)
extension type Tilemap(Int32List data) {
  /// Creates a new Tilemap component with the specified dimensions.
  ///
  /// The underlying array size will be `4 + (columns * rows)`.
  Tilemap.create(int columns, int rows, int tileWidth, int tileHeight)
      : this(Int32List(4 + (columns * rows))
          ..[0] = columns
          ..[1] = rows
          ..[2] = tileWidth
          ..[3] = tileHeight);

  /// The number of columns in the tilemap.
  int get columns => data[0];

  /// The number of rows in the tilemap.
  int get rows => data[1];

  /// The width of a single tile in pixels.
  int get tileWidth => data[2];

  /// The height of a single tile in pixels.
  int get tileHeight => data[3];

  /// Gets the total number of tiles.
  int get length => columns * rows;

  /// Gets the tile ID at the specified column and row.
  ///
  /// Returns 0 (or a default invalid value) if out of bounds, though
  /// caller should ensure bounds are valid.
  int getTile(int col, int row) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return 0; // Return empty/invalid tile
    }
    return data[4 + (row * columns) + col];
  }

  /// Sets the tile ID at the specified column and row.
  void setTile(int col, int row, int tileId) {
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return; // Out of bounds
    }
    data[4 + (row * columns) + col] = tileId;
  }
}
