import 'dart:typed_data';

import 'package:sting/engine/ecs/swarm.dart';

/// A 2D spatial hash grid designed for massive entity counts with zero allocations per update.
/// Uses flat arrays to implement a linked list of entities per cell.
class SpatialHashGrid {
  /// The size of a single cell in the grid (e.g., 64x64 pixels).
  final double cellSize;

  /// The inverse of cellSize for fast multiplication instead of division.
  final double _invCellSize;

  /// Number of cells in the grid.
  final int numCells;

  /// Array mapping a cell index to the first entity ID in that cell.
  /// Initialized to -1 (empty).
  final Int32List _cellStart;

  /// Array mapping an entity ID to the next entity ID in the same cell.
  /// Initialized to -1.
  final Int32List _entityNext;

  static const int _h1 = 0x8da6b343;
  static const int _h2 = 0xd8163841;

  /// Creates a SpatialHashGrid with the specified cell size and total number of cells.
  SpatialHashGrid(this.cellSize, this.numCells)
      : _invCellSize = 1.0 / cellSize,
        _cellStart = Int32List(numCells)..fillRange(0, numCells, -1),
        _entityNext = Int32List(Swarm.maxEntities)
          ..fillRange(0, Swarm.maxEntities, -1);

  /// Computes the 1D hash cell index for the given 2D cell coordinates.
  int _hash(int cellX, int cellY) {
    // Avoid negative values for modulo
    int h = (cellX * _h1) ^ (cellY * _h2);
    // h &= 0x7fffffff to force positive, but bitwise ops on int in Dart can be tricky if we want exact 32 bit unsigned.
    // % numCells handles negative modulo if we do (h % numCells + numCells) % numCells
    int index = h % numCells;
    if (index < 0) index += numCells;
    return index;
  }

  /// Inserts an entity into the grid based on its position (x, y).
  void insert(int entity, double x, double y) {
    if (entity < 0 || entity >= Swarm.maxEntities) {
      throw RangeError.value(
          entity, 'entity', 'Must be between 0 and ${Swarm.maxEntities - 1}');
    }

    final int cellX = (x * _invCellSize).floor();
    final int cellY = (y * _invCellSize).floor();

    final int cellIndex = _hash(cellX, cellY);

    // Insert at the head of the linked list for this cell
    _entityNext[entity] = _cellStart[cellIndex];
    _cellStart[cellIndex] = entity;
  }

  /// Clears the grid in O(numCells) time.
  void clear() {
    // We only need to reset the heads of the linked lists.
    // The _entityNext array will be overwritten when entities are re-inserted.
    for (int i = 0; i < numCells; i++) {
      _cellStart[i] = -1;
    }
  }

  /// Queries the grid for entities within an AABB (Axis-Aligned Bounding Box).
  ///
  /// Calls [callback] for each entity found in the overlapping cells.
  /// Returns early if [callback] returns false, otherwise continues.
  void queryAABB(double x, double y, double width, double height,
      bool Function(int entity) callback) {
    final int minCellX = (x * _invCellSize).floor();
    final int minCellY = (y * _invCellSize).floor();
    final int maxCellX = ((x + width) * _invCellSize).floor();
    final int maxCellY = ((y + height) * _invCellSize).floor();

    for (int cy = minCellY; cy <= maxCellY; cy++) {
      for (int cx = minCellX; cx <= maxCellX; cx++) {
        final int cellIndex = _hash(cx, cy);
        int currentEntity = _cellStart[cellIndex];

        while (currentEntity != -1) {
          final bool continueQuery = callback(currentEntity);
          if (!continueQuery) {
            return;
          }
          currentEntity = _entityNext[currentEntity];
        }
      }
    }
  }

  /// Queries the grid for entities occupying the same cell as the given point.
  ///
  /// Calls [callback] for each entity found in the cell.
  void queryPoint(double x, double y, void Function(int entity) callback) {
    final int cellX = (x * _invCellSize).floor();
    final int cellY = (y * _invCellSize).floor();
    final int cellIndex = _hash(cellX, cellY);

    int currentEntity = _cellStart[cellIndex];
    while (currentEntity != -1) {
      callback(currentEntity);
      currentEntity = _entityNext[currentEntity];
    }
  }
}
