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

  /// Maximum nodes to allow per grid. A node is a single instance of an entity in a cell.
  final int _maxNodes;

  /// Array mapping a cell index to the first node ID in that cell.
  /// Initialized to -1 (empty).
  final Int32List _cellStart;

  /// Array mapping a node ID to the entity ID it represents.
  final Int32List _nodeEntity;

  /// Array mapping a node ID to the next node ID in the same cell.
  final Int32List _nodeNext;

  /// Array mapping an entity ID to its collision layer mask.
  final Int32List _entityLayers;

  /// Tracks which query ID an entity was last returned in to prevent duplicates.
  final Int32List _entityLastQuery;

  /// Current node allocation count.
  int _nodeCount = 0;

  /// Current query ID for deduplication.
  int _currentQueryId = 0;

  static const int _h1 = 0x8da6b343;
  static const int _h2 = 0xd8163841;

  /// Creates a SpatialHashGrid with the specified cell size and total number of cells.
  /// [_maxNodes] determines the maximum total insertions across all cells.
  SpatialHashGrid(this.cellSize, this.numCells, {int maxNodes = Swarm.maxEntities * 4})
      : _invCellSize = 1.0 / cellSize,
        _maxNodes = maxNodes,
        _cellStart = Int32List(numCells)..fillRange(0, numCells, -1),
        _nodeEntity = Int32List(maxNodes),
        _nodeNext = Int32List(maxNodes),
        _entityLayers = Int32List(Swarm.maxEntities),
        _entityLastQuery = Int32List(Swarm.maxEntities);

  /// Computes the 1D hash cell index for the given 2D cell coordinates.
  int _hash(int cellX, int cellY) {
    int h = (cellX * _h1) ^ (cellY * _h2);
    int index = h % numCells;
    if (index < 0) index += numCells;
    return index;
  }

  /// Inserts a node into a specific cell.
  void _insertNode(int entity, int cellIndex) {
    if (_nodeCount >= _maxNodes) {
      // If we run out of nodes, we just drop the insertion to avoid allocation.
      // In a real scenario, maxNodes should be sized appropriately.
      return;
    }

    final int nodeId = _nodeCount++;
    _nodeEntity[nodeId] = entity;

    // Insert at the head of the linked list for this cell
    _nodeNext[nodeId] = _cellStart[cellIndex];
    _cellStart[cellIndex] = nodeId;
  }

  /// Inserts an entity into the grid based on its point position (x, y).
  void insertPoint(int entity, double x, double y, [int layer = 1]) {
    if (entity < 0 || entity >= Swarm.maxEntities) {
      throw RangeError.value(
          entity, 'entity', 'Must be between 0 and ${Swarm.maxEntities - 1}');
    }

    _entityLayers[entity] = layer;

    final int cellX = (x * _invCellSize).floor();
    final int cellY = (y * _invCellSize).floor();
    final int cellIndex = _hash(cellX, cellY);

    _insertNode(entity, cellIndex);
  }

  /// Inserts an entity into the grid based on its Axis-Aligned Bounding Box.
  void insertAABB(int entity, double minX, double minY, double maxX, double maxY, [int layer = 1]) {
    if (entity < 0 || entity >= Swarm.maxEntities) {
      throw RangeError.value(
          entity, 'entity', 'Must be between 0 and ${Swarm.maxEntities - 1}');
    }

    _entityLayers[entity] = layer;

    final int minCellX = (minX * _invCellSize).floor();
    final int minCellY = (minY * _invCellSize).floor();
    final int maxCellX = (maxX * _invCellSize).floor();
    final int maxCellY = (maxY * _invCellSize).floor();

    for (int cy = minCellY; cy <= maxCellY; cy++) {
      for (int cx = minCellX; cx <= maxCellX; cx++) {
        final int cellIndex = _hash(cx, cy);
        _insertNode(entity, cellIndex);
      }
    }
  }

  /// Clears the grid in O(numCells) time.
  void clear() {
    _nodeCount = 0;
    for (int i = 0; i < numCells; i++) {
      _cellStart[i] = -1;
    }
  }

  /// Queries the grid for entities within an AABB (Axis-Aligned Bounding Box).
  ///
  /// Calls [callback] for each entity found in the overlapping cells that matches [mask].
  /// Returns early if [callback] returns false, otherwise continues.
  void queryAABB(double x, double y, double width, double height,
      bool Function(int entity) callback, [int mask = 0xFFFFFFFF]) {
    _currentQueryId++;
    final int queryId = _currentQueryId;

    final int minCellX = (x * _invCellSize).floor();
    final int minCellY = (y * _invCellSize).floor();
    final int maxCellX = ((x + width) * _invCellSize).floor();
    final int maxCellY = ((y + height) * _invCellSize).floor();

    for (int cy = minCellY; cy <= maxCellY; cy++) {
      for (int cx = minCellX; cx <= maxCellX; cx++) {
        final int cellIndex = _hash(cx, cy);
        int currentNode = _cellStart[cellIndex];

        while (currentNode != -1) {
          final int entity = _nodeEntity[currentNode];

          if (_entityLastQuery[entity] != queryId) {
            _entityLastQuery[entity] = queryId;

            if ((_entityLayers[entity] & mask) != 0) {
              final bool continueQuery = callback(entity);
              if (!continueQuery) {
                return;
              }
            }
          }

          currentNode = _nodeNext[currentNode];
        }
      }
    }
  }

  /// Queries the grid for entities occupying the same cell as the given point.
  ///
  /// Calls [callback] for each entity found in the cell that matches [mask].
  void queryPoint(double x, double y, void Function(int entity) callback, [int mask = 0xFFFFFFFF]) {
    _currentQueryId++;
    final int queryId = _currentQueryId;

    final int cellX = (x * _invCellSize).floor();
    final int cellY = (y * _invCellSize).floor();
    final int cellIndex = _hash(cellX, cellY);

    int currentNode = _cellStart[cellIndex];
    while (currentNode != -1) {
      final int entity = _nodeEntity[currentNode];

      if (_entityLastQuery[entity] != queryId) {
        _entityLastQuery[entity] = queryId;

        if ((_entityLayers[entity] & mask) != 0) {
          callback(entity);
        }
      }

      currentNode = _nodeNext[currentNode];
    }
  }

  /// Queries the grid for entities within a given radius from a point.
  /// Broad-phase only: returns entities in cells that intersect the bounding box of the circle.
  ///
  /// Calls [callback] for each entity found that matches [mask].
  /// Returns early if [callback] returns false, otherwise continues.
  void queryRadius(double x, double y, double radius,
      bool Function(int entity) callback, [int mask = 0xFFFFFFFF]) {
    queryAABB(x - radius, y - radius, radius * 2, radius * 2, callback, mask);
  }
}
