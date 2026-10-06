import 'dart:typed_data';

/// A flat component representing a collection of connected line segments on a hex grid.
/// Useful for rendering magistral networks, borders, and UI highlights between hexes.
///
/// Memory layout:
/// - Index 0: maxEdges (float)
/// - Index 1: edgeCount (float)
/// - Index 2: isFlatTopped (1.0 for true, 0.0 for false)
/// - Index 3: hexSize (float)
/// - Data block per edge (6 floats per edge):
///   - Offset + 0: q1 (float)
///   - Offset + 1: r1 (float)
///   - Offset + 2: q2 (float)
///   - Offset + 3: r2 (float)
///   - Offset + 4: color (float representation of 32-bit ARGB, viewable via Uint32List)
///   - Offset + 5: width (float)
extension type HexEdgeMesh(Float32List data) {
  static const int _headerSize = 4;
  static const int _edgeStride = 6;

  /// Creates a new HexEdgeMesh capable of storing up to [maxEdges].
  factory HexEdgeMesh.create({
    required int maxEdges,
    required bool isFlatTopped,
    required double hexSize,
  }) {
    final list = Float32List(_headerSize + maxEdges * _edgeStride);
    list[0] = maxEdges.toDouble();
    list[1] = 0.0; // edgeCount
    list[2] = isFlatTopped ? 1.0 : 0.0;
    list[3] = hexSize;
    return HexEdgeMesh(list);
  }

  /// Maximum number of edge segments this mesh can store.
  int get maxEdges => data[0].toInt();

  /// Current number of stored edges.
  int get edgeCount => data[1].toInt();

  /// Whether the target hex grid is flat-topped (1) or pointy-topped (0).
  int get isFlatTopped => data[2].toInt();

  /// The distance from the center of the hex to its corners.
  double get hexSize => data[3];

  /// Adds a new edge segment between hex centers (q1, r1) and (q2, r2).
  ///
  /// The [color] should be a 32-bit ARGB integer. It is cast via the buffer's Uint32List view
  /// to avoid precision loss in the 24-bit mantissa.
  /// Returns true if successful, false if capacity is full.
  bool addEdge(int q1, int r1, int q2, int r2, int color, double width) {
    final count = edgeCount;
    if (count >= maxEdges) {
      return false;
    }

    final offset = _headerSize + count * _edgeStride;
    data[offset] = q1.toDouble();
    data[offset + 1] = r1.toDouble();
    data[offset + 2] = q2.toDouble();
    data[offset + 3] = r2.toDouble();
    data[offset + 5] = width;

    // Use Uint32List view to store color without float precision loss
    final uint32View = data.buffer.asUint32List(data.offsetInBytes, data.length);
    uint32View[offset + 4] = color;

    data[1] = (count + 1).toDouble();
    return true;
  }

  /// Retrieves an edge at the specified index.
  /// Returns (q1, r1, q2, r2, color, width).
  (int, int, int, int, int, double) getEdge(int index) {
    if (index < 0 || index >= edgeCount) {
      throw RangeError.index(index, this, 'index', 'Index out of range', edgeCount);
    }

    final offset = _headerSize + index * _edgeStride;
    final uint32View = data.buffer.asUint32List(data.offsetInBytes, data.length);

    return (
      data[offset].toInt(),
      data[offset + 1].toInt(),
      data[offset + 2].toInt(),
      data[offset + 3].toInt(),
      uint32View[offset + 4],
      data[offset + 5]
    );
  }

  /// Clears all edges, setting the count to 0 without freeing memory.
  void clear() {
    data[1] = 0.0;
  }
}
