import 'dart:typed_data';
import 'dart:math' as math;
import '../components/movement_queue.dart';
import '../math/hex_math.dart';
import '../math/indexed_min_heap.dart';

/// The grid layout type for pathfinding evaluation.
enum PathfindingGridType {
  rectangular,
  rectangular8Way,
  hexagonal,
}

/// A zero-allocation A* grid pathfinder.
/// Pre-allocates arrays up to [maxNodes] capacity.
class GridPathfinder {
  final int maxNodes;
  final Float32List gScore;
  final Float32List fScore;
  final Int32List cameFrom;
  final Uint8List nodeState; // 0 = unvisited, 1 = open, 2 = closed
  final Int32List _pathBuffer;
  late final IndexedMinHeap _openSet;

  GridPathfinder(this.maxNodes)
      : gScore = Float32List(maxNodes),
        fScore = Float32List(maxNodes),
        cameFrom = Int32List(maxNodes),
        nodeState = Uint8List(maxNodes),
        _pathBuffer = Int32List(maxNodes) {
    _openSet = IndexedMinHeap(maxNodes, fScore);
  }

  /// Finds a path and writes it directly to the provided [queue].
  /// Returns `true` if a path was successfully found and enqueued.
  /// The [costGrid] uses values <= 0 for impassable cells and > 0 for cost multipliers.
  bool findPath(
    int start,
    int target,
    Int32List costGrid,
    int columns,
    int rows,
    PathfindingGridType type,
    MovementQueue queue,
  ) {
    if (start < 0 || start >= maxNodes || target < 0 || target >= maxNodes) {
      return false;
    }
    if (costGrid[start] <= 0 || costGrid[target] <= 0) {
      return false;
    }

    final int totalNodes = columns * rows;
    if (totalNodes > maxNodes) return false;

    _openSet.clear();
    nodeState.fillRange(0, totalNodes, 0);
    gScore.fillRange(0, totalNodes, double.infinity);
    fScore.fillRange(0, totalNodes, double.infinity);

    gScore[start] = 0.0;
    fScore[start] = _heuristic(start, target, columns, type);
    cameFrom[start] = -1;
    nodeState[start] = 1; // open
    _openSet.push(start);

    while (!_openSet.isEmpty) {
      final int current = _openSet.pop();
      if (current == -1) break;

      if (current == target) {
        _reconstructPath(current, queue);
        return true;
      }

      nodeState[current] = 2; // closed

      final int cx = current % columns;
      final int cy = current ~/ columns;

      _processNeighbors(current, cx, cy, target, costGrid, columns, rows, type);
    }

    return false;
  }

  void _processNeighbors(
    int current,
    int cx,
    int cy,
    int target,
    Int32List costGrid,
    int columns,
    int rows,
    PathfindingGridType type,
  ) {
    if (type == PathfindingGridType.rectangular ||
        type == PathfindingGridType.rectangular8Way) {
      final int dirCount = type == PathfindingGridType.rectangular ? 4 : 8;
      for (int i = 0; i < dirCount; i++) {
        final int nx = cx + _rectDx[i];
        final int ny = cy + _rectDy[i];
        if (nx >= 0 && nx < columns && ny >= 0 && ny < rows) {
          final int neighbor = nx + ny * columns;
          if (costGrid[neighbor] <= 0) continue;

          if (type == PathfindingGridType.rectangular8Way && i >= 4) {
            // Prevent corner cutting
            final int corner1 = nx + cy * columns;
            final int corner2 = cx + ny * columns;
            if (costGrid[corner1] <= 0 || costGrid[corner2] <= 0) continue;
          }

          final double stepCost = _rectCost[i] * costGrid[neighbor];
          _evaluateNeighbor(current, neighbor, stepCost, target, columns, type);
        }
      }
    } else if (type == PathfindingGridType.hexagonal) {
      for (int i = 0; i < 6; i++) {
        final int nx = cx + HexMath.neighborDq(i);
        final int ny = cy + HexMath.neighborDr(i);
        if (nx >= 0 && nx < columns && ny >= 0 && ny < rows) {
          final int neighbor = nx + ny * columns;
          if (costGrid[neighbor] <= 0) continue;

          final double stepCost = 1.0 * costGrid[neighbor];
          _evaluateNeighbor(current, neighbor, stepCost, target, columns, type);
        }
      }
    }
  }

  void _evaluateNeighbor(
    int current,
    int neighbor,
    double stepCost,
    int target,
    int columns,
    PathfindingGridType type,
  ) {
    if (nodeState[neighbor] == 2) return;

    final double tentativeG = gScore[current] + stepCost;
    if (nodeState[neighbor] == 0 || tentativeG < gScore[neighbor]) {
      cameFrom[neighbor] = current;
      gScore[neighbor] = tentativeG;
      fScore[neighbor] =
          tentativeG + _heuristic(neighbor, target, columns, type);

      if (nodeState[neighbor] == 0) {
        nodeState[neighbor] = 1;
        _openSet.push(neighbor);
      } else {
        _openSet.decreaseKey(neighbor);
      }
    }
  }

  double _heuristic(int a, int b, int columns, PathfindingGridType type) {
    final int ax = a % columns;
    final int ay = a ~/ columns;
    final int bx = b % columns;
    final int by = b ~/ columns;

    if (type == PathfindingGridType.rectangular) {
      return (ax - bx).abs().toDouble() +
          (ay - by).abs().toDouble(); // Manhattan
    } else if (type == PathfindingGridType.rectangular8Way) {
      final double dx = (ax - bx).abs().toDouble();
      final double dy = (ay - by).abs().toDouble();
      return math.max(dx, dy) +
          (1.41421356237 - 1.0) * math.min(dx, dy); // Octile
    } else {
      return HexMath.hexDistance(ax, ay, bx, by).toDouble();
    }
  }

  void _reconstructPath(int current, MovementQueue queue) {
    int count = 0;
    int curr = current;
    while (curr != -1) {
      _pathBuffer[count++] = curr;
      curr = cameFrom[curr];
    }

    queue.clear();
    for (int i = count - 1; i >= 0; i--) {
      queue.enqueue(_pathBuffer[i]);
    }
  }

  static const List<int> _rectDx = [0, 1, 0, -1, 1, 1, -1, -1];
  static const List<int> _rectDy = [-1, 0, 1, 0, -1, 1, -1, 1];
  static const List<double> _rectCost = [
    1.0,
    1.0,
    1.0,
    1.0,
    1.41421356237,
    1.41421356237,
    1.41421356237,
    1.41421356237
  ];
}
