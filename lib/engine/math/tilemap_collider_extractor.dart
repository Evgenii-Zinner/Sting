import 'dart:typed_data';

import 'package:sting/engine/math/isometric_math.dart';

/// The type of grid the tilemap uses.
enum GridType {
  /// A standard square or rectangular orthogonal grid.
  orthogonal,

  /// A diamond isometric grid where tiles are rotated 45 degrees.
  isometricDiamond,

  /// A staggered isometric grid. (Not supported for polygon extraction).
  isometricStaggered,
}

/// A zero-allocation utility for extracting contiguous collision shapes from a grid.
///
/// Uses a greedy meshing algorithm to merge adjacent solid tiles into larger
/// rectangular AABBs or polygonal regions, drastically reducing collider counts.
class TilemapColliderExtractor {
  final int _columns;
  final int _rows;
  final Uint8List _visited;
  final Float32List _tempCoord = Float32List(2);

  /// Creates a new extractor with an internal visited buffer sized for
  /// a grid of [columns] x [rows].
  TilemapColliderExtractor(this._columns, this._rows)
      : _visited = Uint8List(_columns * _rows);

  /// Greedily extracts rectangular AABBs from an orthogonal grid.
  ///
  /// Merges contiguous blocks of tiles where [isSolid] returns true.
  /// The results are written to [outBuffer] as a flat list of floats:
  /// `[x, y, width, height, x, y, width, height, ...]`.
  ///
  /// Returns the total number of floats written to the buffer.
  /// If the buffer is too small, extraction stops and returns what was written.
  int extractOrthogonalAABBs(
      double tileWidth, double tileHeight, bool Function(int x, int y) isSolid, Float32List outBuffer) {
    _visited.fillRange(0, _visited.length, 0);
    int floatsWritten = 0;

    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _columns; x++) {
        final index = y * _columns + x;
        if (_visited[index] == 1 || !isSolid(x, y)) {
          continue;
        }

        // Find the width of the contiguous block
        int endX = x + 1;
        while (endX < _columns && _visited[y * _columns + endX] == 0 && isSolid(endX, y)) {
          endX++;
        }
        int w = endX - x;

        // Find the height of the contiguous block
        int endY = y + 1;
        bool keepGoing = true;
        while (endY < _rows && keepGoing) {
          for (int ix = x; ix < endX; ix++) {
            if (_visited[endY * _columns + ix] == 1 || !isSolid(ix, endY)) {
              keepGoing = false;
              break;
            }
          }
          if (keepGoing) {
            endY++;
          }
        }
        int h = endY - y;

        // Mark block as visited
        for (int iy = y; iy < endY; iy++) {
          for (int ix = x; ix < endX; ix++) {
            _visited[iy * _columns + ix] = 1;
          }
        }

        // Write AABB to buffer
        if (floatsWritten + 4 <= outBuffer.length) {
          outBuffer[floatsWritten++] = x * tileWidth;
          outBuffer[floatsWritten++] = y * tileHeight;
          outBuffer[floatsWritten++] = w * tileWidth;
          outBuffer[floatsWritten++] = h * tileHeight;
        } else {
          return floatsWritten; // Buffer full
        }
      }
    }
    return floatsWritten;
  }

  /// Greedily extracts 4-sided convex polygons from the grid.
  ///
  /// Merges contiguous blocks of tiles where [isSolid] returns true.
  /// The results are written to [outBuffer] as a flat list of 8 floats per polygon
  /// representing the 4 vertices (clockwise or counter-clockwise depending on grid mapping):
  /// `[x0, y0, x1, y1, x2, y2, x3, y3, ...]`.
  ///
  /// Supports [GridType.orthogonal] and [GridType.isometricDiamond].
  /// Throws [ArgumentError] if [GridType.isometricStaggered] is provided.
  ///
  /// Returns the total number of floats written to the buffer.
  int extractPolygons(GridType gridType, double tileWidth, double tileHeight,
      bool Function(int x, int y) isSolid, Float32List outBuffer) {
    if (gridType == GridType.isometricStaggered) {
      throw ArgumentError('Polygon extraction not supported for Staggered isometric grids.');
    }

    _visited.fillRange(0, _visited.length, 0);
    int floatsWritten = 0;

    for (int y = 0; y < _rows; y++) {
      for (int x = 0; x < _columns; x++) {
        final index = y * _columns + x;
        if (_visited[index] == 1 || !isSolid(x, y)) {
          continue;
        }

        // Find the width of the contiguous block
        int endX = x + 1;
        while (endX < _columns && _visited[y * _columns + endX] == 0 && isSolid(endX, y)) {
          endX++;
        }
        int w = endX - x;

        // Find the height of the contiguous block
        int endY = y + 1;
        bool keepGoing = true;
        while (endY < _rows && keepGoing) {
          for (int ix = x; ix < endX; ix++) {
            if (_visited[endY * _columns + ix] == 1 || !isSolid(ix, endY)) {
              keepGoing = false;
              break;
            }
          }
          if (keepGoing) {
            endY++;
          }
        }
        int h = endY - y;

        // Mark block as visited
        for (int iy = y; iy < endY; iy++) {
          for (int ix = x; ix < endX; ix++) {
            _visited[iy * _columns + ix] = 1;
          }
        }

        if (floatsWritten + 8 <= outBuffer.length) {
          if (gridType == GridType.orthogonal) {
            // Top-left
            outBuffer[floatsWritten++] = x * tileWidth;
            outBuffer[floatsWritten++] = y * tileHeight;
            // Top-right
            outBuffer[floatsWritten++] = (x + w) * tileWidth;
            outBuffer[floatsWritten++] = y * tileHeight;
            // Bottom-right
            outBuffer[floatsWritten++] = (x + w) * tileWidth;
            outBuffer[floatsWritten++] = (y + h) * tileHeight;
            // Bottom-left
            outBuffer[floatsWritten++] = x * tileWidth;
            outBuffer[floatsWritten++] = (y + h) * tileHeight;
          } else if (gridType == GridType.isometricDiamond) {
            // Isometric diamond vertices need to be converted to world space.
            // The 4 corners of the merged block (col, row) in grid space are:
            // Top: (x, y)
            // Right: (x + w, y)
            // Bottom: (x + w, y + h)
            // Left: (x, y + h)

            // Top
            IsometricMath.isoToWorldDiamond(x.toDouble(), y.toDouble(), tileWidth, tileHeight, _tempCoord);
            outBuffer[floatsWritten++] = _tempCoord[0];
            outBuffer[floatsWritten++] = _tempCoord[1];

            // Right
            IsometricMath.isoToWorldDiamond((x + w).toDouble(), y.toDouble(), tileWidth, tileHeight, _tempCoord);
            outBuffer[floatsWritten++] = _tempCoord[0];
            outBuffer[floatsWritten++] = _tempCoord[1];

            // Bottom
            IsometricMath.isoToWorldDiamond((x + w).toDouble(), (y + h).toDouble(), tileWidth, tileHeight, _tempCoord);
            outBuffer[floatsWritten++] = _tempCoord[0];
            outBuffer[floatsWritten++] = _tempCoord[1];

            // Left
            IsometricMath.isoToWorldDiamond(x.toDouble(), (y + h).toDouble(), tileWidth, tileHeight, _tempCoord);
            outBuffer[floatsWritten++] = _tempCoord[0];
            outBuffer[floatsWritten++] = _tempCoord[1];
          }
        } else {
          return floatsWritten; // Buffer full
        }
      }
    }
    return floatsWritten;
  }
}
