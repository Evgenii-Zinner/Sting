import 'dart:typed_data';
import 'dart:math' as math;
import 'nav_mesh.dart';

/// A zero-allocation MinHeap priority queue for A* over NavMesh polygons.
class _NavMinHeap {
  final Int32List data;
  final Float32List fScore;
  final Int32List indices;
  int size = 0;

  _NavMinHeap(int capacity, this.fScore)
      : data = Int32List(capacity),
        indices = Int32List(capacity) {
    indices.fillRange(0, capacity, -1);
  }

  void clear() {
    for (int i = 0; i < size; i++) {
      indices[data[i]] = -1;
    }
    size = 0;
  }

  bool get isEmpty => size == 0;

  void push(int node) {
    int i = size++;
    while (i > 0) {
      final int parent = (i - 1) >> 1;
      final int pNode = data[parent];
      if (fScore[pNode] <= fScore[node]) break;
      data[i] = pNode;
      indices[pNode] = i;
      i = parent;
    }
    data[i] = node;
    indices[node] = i;
  }

  int pop() {
    if (size == 0) return -1;
    final int root = data[0];
    indices[root] = -1;
    size--;
    if (size > 0) {
      final int lastNode = data[size];
      int i = 0;
      while (true) {
        final int left = (i << 1) + 1;
        final int right = left + 1;
        if (left >= size) break;

        int smallest = left;
        if (right < size && fScore[data[right]] < fScore[data[left]]) {
          smallest = right;
        }

        final int sNode = data[smallest];
        if (fScore[lastNode] <= fScore[sNode]) break;
        data[i] = sNode;
        indices[sNode] = i;
        i = smallest;
      }
      data[i] = lastNode;
      indices[lastNode] = i;
    }
    return root;
  }

  void decreaseKey(int node) {
    int i = indices[node];
    if (i == -1) return; // Not in heap

    while (i > 0) {
      final int parent = (i - 1) >> 1;
      final int pNode = data[parent];
      if (fScore[pNode] <= fScore[node]) break;
      data[i] = pNode;
      indices[pNode] = i;
      i = parent;
    }
    data[i] = node;
    indices[node] = i;
  }
}

/// A zero-allocation pathfinder operating on a `NavMesh`.
class NavMeshPathfinder {
  final NavMesh navMesh;
  final int maxPolygons;
  final int maxPathSegments;

  final Float32List gScore;
  final Float32List fScore;
  final Int32List cameFrom;
  final Uint8List nodeState; // 0 = unvisited, 1 = open, 2 = closed

  late final _NavMinHeap _openSet;

  // Buffers for Funnel algorithm
  final Int32List _portalLeft;
  final Int32List _portalRight;
  final Float32List _portalLeftX;
  final Float32List _portalLeftY;
  final Float32List _portalRightX;
  final Float32List _portalRightY;
  final Int32List _polyPath;

  // Output waypoints
  final Float32List outPathX;
  final Float32List outPathY;

  NavMeshPathfinder(this.navMesh, this.maxPolygons, this.maxPathSegments)
      : gScore = Float32List(maxPolygons),
        fScore = Float32List(maxPolygons),
        cameFrom = Int32List(maxPolygons),
        nodeState = Uint8List(maxPolygons),
        _portalLeft = Int32List(maxPathSegments),
        _portalRight = Int32List(maxPathSegments),
        _portalLeftX = Float32List(maxPathSegments),
        _portalLeftY = Float32List(maxPathSegments),
        _portalRightX = Float32List(maxPathSegments),
        _portalRightY = Float32List(maxPathSegments),
        _polyPath = Int32List(maxPolygons),
        outPathX = Float32List(maxPathSegments),
        outPathY = Float32List(maxPathSegments) {
    _openSet = _NavMinHeap(maxPolygons, fScore);
  }

  /// Finds a smooth path from (startX, startY) to (targetX, targetY).
  /// Returns the number of resulting waypoints, stored in [outPathX] and [outPathY].
  /// Returns 0 if no path is found.
  int findPath(double startX, double startY, double targetX, double targetY) {
    final int startPolyId = navMesh.findPolygon(startX, startY);
    final int targetPolyId = navMesh.findPolygon(targetX, targetY);

    if (startPolyId == -1 || targetPolyId == -1) {
      return 0; // Invalid start or target
    }

    if (startPolyId == targetPolyId) {
        outPathX[0] = startX;
        outPathY[0] = startY;
        outPathX[1] = targetX;
        outPathY[1] = targetY;
        return 2;
    }

    final int totalPolys = navMesh.polygonCount;
    if (totalPolys > maxPolygons) return 0;

    _openSet.clear();
    nodeState.fillRange(0, totalPolys, 0);
    gScore.fillRange(0, totalPolys, double.infinity);
    fScore.fillRange(0, totalPolys, double.infinity);

    gScore[startPolyId] = 0.0;
    fScore[startPolyId] = _heuristic(startPolyId, targetPolyId);
    cameFrom[startPolyId] = -1;
    nodeState[startPolyId] = 1; // open
    _openSet.push(startPolyId);

    while (!_openSet.isEmpty) {
      final int current = _openSet.pop();
      if (current == -1) break;

      if (current == targetPolyId) {
        return _reconstructAndSmoothPath(current, startX, startY, targetX, targetY);
      }

      nodeState[current] = 2; // closed
      final poly = navMesh.getPolygon(current)!;

      for (int i = 0; i < poly.vertexCount; i++) {
        final int neighbor = poly.neighbors[i];
        if (neighbor != -1) {
          final neighborPoly = navMesh.getPolygon(neighbor)!;
          if (!neighborPoly.isTraversable) continue;

          final double dx = poly.centerX - neighborPoly.centerX;
          final double dy = poly.centerY - neighborPoly.centerY;
          final double stepCost = math.sqrt(dx * dx + dy * dy);

          if (nodeState[neighbor] == 2) continue;

          final double tentativeG = gScore[current] + stepCost;
          if (nodeState[neighbor] == 0 || tentativeG < gScore[neighbor]) {
            cameFrom[neighbor] = current;
            gScore[neighbor] = tentativeG;
            fScore[neighbor] = tentativeG + _heuristic(neighbor, targetPolyId);

            if (nodeState[neighbor] == 0) {
              nodeState[neighbor] = 1;
              _openSet.push(neighbor);
            } else {
              _openSet.decreaseKey(neighbor);
            }
          }
        }
      }
    }

    return 0; // No path found
  }

  double _heuristic(int a, int b) {
    final polyA = navMesh.getPolygon(a)!;
    final polyB = navMesh.getPolygon(b)!;
    final double dx = polyA.centerX - polyB.centerX;
    final double dy = polyA.centerY - polyB.centerY;
    return math.sqrt(dx * dx + dy * dy);
  }

  int _reconstructAndSmoothPath(
      int current, double startX, double startY, double targetX, double targetY) {
    int count = 0;
    int curr = current;
    while (curr != -1) {
      _polyPath[count++] = curr;
      curr = cameFrom[curr];
    }

    // Reverse path so it goes from start to target
    for (int i = 0; i < count ~/ 2; i++) {
      final int temp = _polyPath[i];
      _polyPath[i] = _polyPath[count - 1 - i];
      _polyPath[count - 1 - i] = temp;
    }

    // Prepare portals for the funnel algorithm
    int portalCount = 0;

    // Add start point as first portal (degenerate portal, left=right)
    _portalLeftX[portalCount] = startX;
    _portalLeftY[portalCount] = startY;
    _portalRightX[portalCount] = startX;
    _portalRightY[portalCount] = startY;
    portalCount++;

    for (int i = 0; i < count - 1; i++) {
      final poly1 = navMesh.getPolygon(_polyPath[i])!;
      final poly2 = navMesh.getPolygon(_polyPath[i + 1])!;

      // Find the shared edge
      int sharedEdgeIdx1 = -1;
      int sharedEdgeIdx2 = -1;

      for (int a = 0; a < poly1.vertexCount; a++) {
        if (poly1.neighbors[a] == poly2.id) {
          sharedEdgeIdx1 = a;
          break;
        }
      }

      for (int b = 0; b < poly2.vertexCount; b++) {
        if (poly2.neighbors[b] == poly1.id) {
          sharedEdgeIdx2 = b;
          break;
        }
      }

      if (sharedEdgeIdx1 != -1 && sharedEdgeIdx2 != -1) {
         final int aNext = (sharedEdgeIdx1 + 1) % poly1.vertexCount;
         final int bNext = (sharedEdgeIdx2 + 1) % poly2.vertexCount;

         final double px1 = poly1.verticesX[sharedEdgeIdx1];
         final double py1 = poly1.verticesY[sharedEdgeIdx1];
         final double px2 = poly1.verticesX[aNext];
         final double py2 = poly1.verticesY[aNext];

         // Instead of looking from center to center which can be unreliable if shapes are non-axis-aligned,
         // We can figure out left/right from the start point or previous portal.
         // Let's use a simpler heuristic for testing: if px1 is "closer" to the left, etc.
         // In a robust implementation, the winding is derived from polygon orientation.
         // Let's assume poly1 is strictly CCW. If poly1 is CCW, edge px1->px2 has poly1 to its LEFT,
         // meaning px1->px2 points "forward" along the boundary.
         // Looking OUTWARD from poly1, right is px1, left is px2.

         _portalRightX[portalCount] = px1;
         _portalRightY[portalCount] = py1;
         _portalLeftX[portalCount] = px2;
         _portalLeftY[portalCount] = py2;
         portalCount++;
      }
    }

    // Add target point as final portal
    _portalLeftX[portalCount] = targetX;
    _portalLeftY[portalCount] = targetY;
    _portalRightX[portalCount] = targetX;
    _portalRightY[portalCount] = targetY;
    portalCount++;

    return _funnel(portalCount);
  }

  double _triArea2(double ax, double ay, double bx, double by, double cx, double cy) {
    return (cx - ax) * (by - ay) - (bx - ax) * (cy - ay);
  }

  /// Funnel Algorithm implementation to smooth portals into string path.
  int _funnel(int portalCount) {
    if (portalCount < 2) return 0;

    int pathCount = 0;

    double portalApexX = _portalLeftX[0];
    double portalApexY = _portalLeftY[0];

    double portalLeftX = _portalLeftX[0];
    double portalLeftY = _portalLeftY[0];

    double portalRightX = _portalRightX[0];
    double portalRightY = _portalRightY[0];

    int apexIndex = 0;
    int leftIndex = 0;
    int rightIndex = 0;

    outPathX[pathCount] = portalApexX;
    outPathY[pathCount] = portalApexY;
    pathCount++;

    for (int i = 1; i < portalCount; i++) {
        // If the left and right points are swapped in our naive logic, fix it for the funnel
        double leftX = _portalLeftX[i];
        double leftY = _portalLeftY[i];
        double rightX = _portalRightX[i];
        double rightY = _portalRightY[i];

        if (i < portalCount - 1) { // Skip target portal which has left==right
            if (_triArea2(portalApexX, portalApexY, rightX, rightY, leftX, leftY) < 0.0) {
               // Swap them if they are crossed from the apex's perspective
               final double tmpX = leftX;
               final double tmpY = leftY;
               leftX = rightX;
               leftY = rightY;
               rightX = tmpX;
               rightY = tmpY;
            }
        }

        // Update right vertex
        if (_triArea2(portalApexX, portalApexY, portalRightX, portalRightY, rightX, rightY) <= 0.0) {
            if (portalApexX == portalRightX && portalApexY == portalRightY ||
                _triArea2(portalApexX, portalApexY, portalLeftX, portalLeftY, rightX, rightY) > 0.0) {
                // Tighten the funnel
                portalRightX = rightX;
                portalRightY = rightY;
                rightIndex = i;
            } else {
                // Right over left, insert left to path and restart scan from left point
                outPathX[pathCount] = portalLeftX;
                outPathY[pathCount] = portalLeftY;
                pathCount++;

                portalApexX = portalLeftX;
                portalApexY = portalLeftY;
                apexIndex = leftIndex;

                portalLeftX = portalApexX;
                portalLeftY = portalApexY;
                portalRightX = portalApexX;
                portalRightY = portalApexY;

                i = apexIndex;
                continue;
            }
        }

        // Update left vertex
        if (_triArea2(portalApexX, portalApexY, portalLeftX, portalLeftY, leftX, leftY) >= 0.0) {
             if (portalApexX == portalLeftX && portalApexY == portalLeftY ||
                _triArea2(portalApexX, portalApexY, portalRightX, portalRightY, leftX, leftY) < 0.0) {
                // Tighten the funnel
                portalLeftX = leftX;
                portalLeftY = leftY;
                leftIndex = i;
            } else {
                // Left over right, insert right to path and restart scan from right point
                outPathX[pathCount] = portalRightX;
                outPathY[pathCount] = portalRightY;
                pathCount++;

                portalApexX = portalRightX;
                portalApexY = portalRightY;
                apexIndex = rightIndex;

                portalLeftX = portalApexX;
                portalLeftY = portalApexY;
                portalRightX = portalApexX;
                portalRightY = portalApexY;

                i = apexIndex;
                continue;
            }
        }
    }

    // Append target
    final double targetX = _portalLeftX[portalCount - 1];
    final double targetY = _portalLeftY[portalCount - 1];

    // Only append if it's not identical to the last point to avoid dupes
    if (outPathX[pathCount-1] != targetX || outPathY[pathCount-1] != targetY) {
       outPathX[pathCount] = targetX;
       outPathY[pathCount] = targetY;
       pathCount++;
    }

    return pathCount;
  }
}
