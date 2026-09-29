import 'dart:math' as math;
import 'dart:typed_data';
import 'nav_mesh.dart';

class RaycastHit {
  bool hit = false;
  double pointX = 0.0;
  double pointY = 0.0;
  double normalX = 0.0;
  double normalY = 0.0;
  double distance = 0.0;
  double fraction = 0.0;
  int edgeIndex = -1;

  void copyFrom(RaycastHit other) {
    hit = other.hit;
    pointX = other.pointX;
    pointY = other.pointY;
    normalX = other.normalX;
    normalY = other.normalY;
    distance = other.distance;
    fraction = other.fraction;
    edgeIndex = other.edgeIndex;
  }

  void reset() {
    hit = false;
    pointX = 0.0;
    pointY = 0.0;
    normalX = 0.0;
    normalY = 0.0;
    distance = 0.0;
    fraction = 0.0;
    edgeIndex = -1;
  }
}

class Raycast2D {
  static final RaycastHit _tempHit = RaycastHit();

  static void raycastSegment(
    double ox,
    double oy,
    double dx,
    double dy,
    double maxDist,
    double x1,
    double y1,
    double x2,
    double y2,
    RaycastHit outHit,
  ) {
    final double s2x = x2 - x1;
    final double s2y = y2 - y1;

    final double det = dx * s2y - dy * s2x;

    if (det == 0.0) {
      outHit.hit = false;
      return;
    }

    final double s1x = x1 - ox;
    final double s1y = y1 - oy;

    final double t = (s1x * s2y - s1y * s2x) / det;
    final double u = (s1x * dy - s1y * dx) / det;

    if (t >= 0.0 && t <= maxDist && u >= 0.0 && u <= 1.0) {
      outHit.hit = true;
      outHit.pointX = ox + t * dx;
      outHit.pointY = oy + t * dy;
      outHit.distance = t;
      outHit.fraction = maxDist > 0.0 ? t / maxDist : 0.0;
      outHit.edgeIndex = -1;

      double nx = -s2y;
      double ny = s2x;
      final double len = math.sqrt(nx * nx + ny * ny);
      if (len > 0.0) {
        nx /= len;
        ny /= len;
      }

      if (dx * nx + dy * ny > 0.0) {
        nx = -nx;
        ny = -ny;
      }

      outHit.normalX = nx;
      outHit.normalY = ny;
    } else {
      outHit.hit = false;
    }
  }

  static void raycastPolyline(
    double ox,
    double oy,
    double dx,
    double dy,
    double maxDist,
    Float32List polyline,
    RaycastHit outHit,
  ) {
    outHit.reset();
    outHit.distance = double.infinity;

    for (int i = 0; i < polyline.length - 2; i += 2) {
      final double x1 = polyline[i];
      final double y1 = polyline[i + 1];
      final double x2 = polyline[i + 2];
      final double y2 = polyline[i + 3];

      raycastSegment(ox, oy, dx, dy, maxDist, x1, y1, x2, y2, _tempHit);

      if (_tempHit.hit && _tempHit.distance < outHit.distance) {
        outHit.copyFrom(_tempHit);
        outHit.edgeIndex = i ~/ 2;
      }
    }

    if (!outHit.hit) {
      outHit.distance = 0.0;
    }
  }

  static void raycastNavMesh(
    double ox,
    double oy,
    double dx,
    double dy,
    double maxDist,
    NavMesh navMesh,
    RaycastHit outHit,
  ) {
    outHit.reset();
    outHit.distance = double.infinity;

    for (int i = 0; i < navMesh.polygonCount; i++) {
      final poly = navMesh.getPolygon(i);
      if (poly == null) continue;

      for (int j = 0; j < poly.vertexCount; j++) {
        final int neighborId = poly.neighbors[j];
        bool isBoundary = false;

        if (neighborId == -1) {
          isBoundary = true;
        } else {
          final neighborPoly = navMesh.getPolygon(neighborId);
          if (neighborPoly != null) {
            if (poly.isTraversable && !neighborPoly.isTraversable) {
              isBoundary = true;
            }
          }
        }

        if (isBoundary) {
          final double x1 = poly.verticesX[j];
          final double y1 = poly.verticesY[j];
          final int next = (j + 1) % poly.vertexCount;
          final double x2 = poly.verticesX[next];
          final double y2 = poly.verticesY[next];

          raycastSegment(ox, oy, dx, dy, maxDist, x1, y1, x2, y2, _tempHit);

          if (_tempHit.hit && _tempHit.distance < outHit.distance) {
            outHit.copyFrom(_tempHit);
            outHit.edgeIndex = j;
          }
        }
      }
    }

    if (!outHit.hit) {
      outHit.distance = 0.0;
    }
  }
}
