import 'dart:math' as math;

/// Zero-allocation mathematical utilities for hexagonal grids using axial coordinates (q, r).
///
/// Handles pointy-topped and flat-topped hexagonal grids without allocating Vector or
/// coordinate objects, utilizing Dart 3 Records for return values where multiple
/// primitives are required.
class HexMath {
  static final double _sqrt3 = math.sqrt(3.0);

  /// Calculates the distance (in number of hexes) between two axial coordinates.
  static int hexDistance(int q1, int r1, int q2, int r2) {
    final int dq = q1 - q2;
    final int dr = r1 - r2;
    return (dq.abs() + dr.abs() + (dq + dr).abs()) ~/ 2;
  }

  /// Converts an axial coordinate (q, r) on a pointy-topped hex grid to world coordinates (x, y).
  ///
  /// [size] is the distance from the center of the hex to any of its corners.
  static (double, double) pointyGridToWorld(int q, int r, double size) {
    final double x = size * _sqrt3 * (q + r / 2.0);
    final double y = size * 3.0 / 2.0 * r;
    return (x, y);
  }

  /// Converts an axial coordinate (q, r) on a flat-topped hex grid to world coordinates (x, y).
  ///
  /// [size] is the distance from the center of the hex to any of its corners.
  static (double, double) flatGridToWorld(int q, int r, double size) {
    final double x = size * 3.0 / 2.0 * q;
    final double y = size * _sqrt3 * (q / 2.0 + r);
    return (x, y);
  }

  /// Converts world coordinates (x, y) to the nearest pointy-topped axial hex coordinate (q, r).
  static (int, int) pointyWorldToGrid(double x, double y, double size) {
    final double qFractional = (_sqrt3 / 3.0 * x - 1.0 / 3.0 * y) / size;
    final double rFractional = (2.0 / 3.0 * y) / size;
    return _axialRound(qFractional, rFractional);
  }

  /// Converts world coordinates (x, y) to the nearest flat-topped axial hex coordinate (q, r).
  static (int, int) flatWorldToGrid(double x, double y, double size) {
    final double qFractional = (2.0 / 3.0 * x) / size;
    final double rFractional = (-1.0 / 3.0 * x + _sqrt3 / 3.0 * y) / size;
    return _axialRound(qFractional, rFractional);
  }

  /// Rounds fractional axial coordinates to the nearest integer axial coordinate.
  static (int, int) _axialRound(double q, double r) {
    return _cubeRound(q, r, -q - r);
  }

  /// Rounds fractional cube coordinates to the nearest integer axial coordinate.
  static (int, int) _cubeRound(double fracQ, double fracR, double fracS) {
    int q = fracQ.round();
    int r = fracR.round();
    int s = fracS.round();

    final double qDiff = (q - fracQ).abs();
    final double rDiff = (r - fracR).abs();
    final double sDiff = (s - fracS).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      q = -r - s;
    } else if (rDiff > sDiff) {
      r = -q - s;
    } else {
      s = -q - r;
    }

    return (q, r);
  }

  // Neighbor offsets in axial coordinates (q, r)
  // Direction 0: +1, 0 (East)
  // Direction 1: +1, -1 (North-East)
  // Direction 2: 0, -1 (North-West)
  // Direction 3: -1, 0 (West)
  // Direction 4: -1, +1 (South-West)
  // Direction 5: 0, +1 (South-East)
  // Note: Directions might vary depending on whether the grid is pointy-topped or flat-topped,
  // but the axial topology is identical. This uses the standard axial neighborhood.

  static const List<int> _neighborDq = [1, 1, 0, -1, -1, 0];
  static const List<int> _neighborDr = [0, -1, -1, 0, 1, 1];

  /// Returns the delta q for the neighbor in the given [direction] (0-5).
  static int neighborDq(int direction) {
    return _neighborDq[direction % 6];
  }

  /// Returns the delta r for the neighbor in the given [direction] (0-5).
  static int neighborDr(int direction) {
    return _neighborDr[direction % 6];
  }

  /// Returns the axial coordinates of the neighbor in the given [direction] (0-5).
  static (int, int) getNeighbor(int q, int r, int direction) {
    final int dir = direction % 6;
    return (q + _neighborDq[dir], r + _neighborDr[dir]);
  }
}
