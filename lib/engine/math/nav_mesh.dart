import 'dart:typed_data';
import 'dart:math' as math;

/// A 2D Polygon representing a continuous navigation area.
class NavPolygon {
  final int id;
  /// X coordinates of vertices.
  final Float32List verticesX;
  /// Y coordinates of vertices.
  final Float32List verticesY;
  final int vertexCount;
  /// Adjacent polygon IDs for each edge. -1 if no neighbor.
  final Int32List neighbors;

  /// Whether this polygon is traversable.
  bool isTraversable = true;

  /// Cached center
  double centerX = 0.0;
  double centerY = 0.0;

  NavPolygon(this.id, List<double> vx, List<double> vy)
      : verticesX = Float32List.fromList(vx),
        verticesY = Float32List.fromList(vy),
        vertexCount = vx.length,
        neighbors = Int32List(vx.length) {
    neighbors.fillRange(0, vertexCount, -1);
    _computeCenter();
  }

  void _computeCenter() {
    centerX = 0.0;
    centerY = 0.0;
    for (int i = 0; i < vertexCount; i++) {
      centerX += verticesX[i];
      centerY += verticesY[i];
    }
    centerX /= vertexCount;
    centerY /= vertexCount;
  }

  /// Returns true if the point is inside the convex polygon.
  bool contains(double x, double y) {
    bool inside = false;
    for (int i = 0, j = vertexCount - 1; i < vertexCount; j = i++) {
      final double xi = verticesX[i], yi = verticesY[i];
      final double xj = verticesX[j], yj = verticesY[j];

      final bool intersect =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}

/// A dynamic polygonal Navigation Mesh for 2D continuous space.
/// Supports zero-allocation queries and pathfinding.
class NavMesh {
  final List<NavPolygon> _polygons = [];

  void addPolygon(NavPolygon poly) {
    _polygons.add(poly);
  }

  NavPolygon? getPolygon(int id) {
    if (id >= 0 && id < _polygons.length) {
      return _polygons[id];
    }
    return null;
  }

  int get polygonCount => _polygons.length;

  /// Finds the traversable polygon containing the point (x, y). Returns -1 if none found.
  int findPolygon(double x, double y) {
    for (int i = 0; i < _polygons.length; i++) {
      if (_polygons[i].isTraversable && _polygons[i].contains(x, y)) {
        return i;
      }
    }
    return -1;
  }

  /// Builds connectivity graph between adjacent polygons.
  void buildNeighbors() {
    for (int i = 0; i < _polygons.length; i++) {
      _polygons[i].neighbors.fillRange(0, _polygons[i].vertexCount, -1);
    }

    for (int i = 0; i < _polygons.length; i++) {
      final polyA = _polygons[i];
      for (int a = 0; a < polyA.vertexCount; a++) {
        if (polyA.neighbors[a] != -1) continue;

        final int aNext = (a + 1) % polyA.vertexCount;
        final double ax1 = polyA.verticesX[a];
        final double ay1 = polyA.verticesY[a];
        final double ax2 = polyA.verticesX[aNext];
        final double ay2 = polyA.verticesY[aNext];

        for (int j = i + 1; j < _polygons.length; j++) {
          final polyB = _polygons[j];
          for (int b = 0; b < polyB.vertexCount; b++) {
            if (polyB.neighbors[b] != -1) continue;

            final int bNext = (b + 1) % polyB.vertexCount;
            final double bx1 = polyB.verticesX[b];
            final double by1 = polyB.verticesY[b];
            final double bx2 = polyB.verticesX[bNext];
            final double by2 = polyB.verticesY[bNext];

            // Edges must be identical but reversed winding
            if (_isSamePoint(ax1, ay1, bx2, by2) && _isSamePoint(ax2, ay2, bx1, by1)) {
              polyA.neighbors[a] = j;
              polyB.neighbors[b] = i;
              break;
            }
          }
        }
      }
    }
  }

  bool _isSamePoint(double x1, double y1, double x2, double y2) {
    const double eps = 1e-4;
    return (x1 - x2).abs() < eps && (y1 - y2).abs() < eps;
  }

  /// Carves an AABB obstacle out of the NavMesh.
  /// Currently just disables connectivity to intersecting polygons to simulate blocking.
  /// In a full implementation, this would perform boolean subtraction and retriangulate.
  void carveAABB(double minX, double minY, double maxX, double maxY) {
    for (int i = 0; i < _polygons.length; i++) {
      final poly = _polygons[i];

      bool overlap = false;

      // Simple AABB overlap check with the polygon's bounding box
      double polyMinX = poly.verticesX[0];
      double polyMaxX = poly.verticesX[0];
      double polyMinY = poly.verticesY[0];
      double polyMaxY = poly.verticesY[0];

      for (int v = 1; v < poly.vertexCount; v++) {
         polyMinX = math.min(polyMinX, poly.verticesX[v]);
         polyMaxX = math.max(polyMaxX, poly.verticesX[v]);
         polyMinY = math.min(polyMinY, poly.verticesY[v]);
         polyMaxY = math.max(polyMaxY, poly.verticesY[v]);
      }

      if (polyMinX <= maxX && polyMaxX >= minX && polyMinY <= maxY && polyMaxY >= minY) {
          overlap = true;
      }

      if (overlap) {
         poly.isTraversable = false;
         // Disconnect from neighbors
         for (int j = 0; j < poly.vertexCount; j++) {
            final neighborId = poly.neighbors[j];
            if (neighborId != -1) {
              final neighborPoly = _polygons[neighborId];
              for(int k=0; k < neighborPoly.vertexCount; k++) {
                if(neighborPoly.neighbors[k] == i) {
                   neighborPoly.neighbors[k] = -1;
                }
              }
              poly.neighbors[j] = -1;
            }
         }
      }
    }
  }
}
