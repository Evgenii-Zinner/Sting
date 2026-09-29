import 'dart:typed_data';

/// A flat SplineFollower component using a Dart extension type over a Float32List.
/// Designed for zero-allocation ECS component architecture.
///
/// Memory layout (first 6 indices are metadata, remaining are spline/polyline points):
/// - Index 0: currentDistance (float) - The distance travelled along the spline or parameter t depending on usage.
/// - Index 1: speed (float) - Speed of advancement.
/// - Index 2: loopMode (float cast to int) - 0: once, 1: loop, 2: pingpong.
/// - Index 3: direction (float) - 1.0 (forward) or -1.0 (backward).
/// - Index 4: alignRotation (float cast to int) - 1: true, 0: false.
/// - Index 5: type (float cast to int) - 0: Polyline, 1: QuadraticBezier, 2: CubicBezier, 3: Hermite.
/// - Index 6+: Points data [x0, y0, x1, y1, ...]
extension type SplineFollower(Float32List data) {
  /// Creates a new SplineFollower component.
  SplineFollower.create({
    required int pointCount,
    double currentDistance = 0.0,
    double speed = 1.0,
    int loopMode = 0,
    double direction = 1.0,
    bool alignRotation = false,
    int type = 0,
  }) : this(Float32List(6 + pointCount * 2)
          ..[0] = currentDistance
          ..[1] = speed
          ..[2] = loopMode.toDouble()
          ..[3] = direction
          ..[4] = alignRotation ? 1.0 : 0.0
          ..[5] = type.toDouble());

  // --- Properties ---

  /// The current distance along the path, or parameter 't' if type is a Bezier.
  double get currentDistance => data[0];
  set currentDistance(double value) => data[0] = value;

  /// The speed of movement.
  double get speed => data[1];
  set speed(double value) => data[1] = value;

  /// The loop mode: 0 (once), 1 (loop), 2 (pingpong).
  int get loopMode => data[2].toInt();
  set loopMode(int value) => data[2] = value.toDouble();

  /// The direction of movement: 1.0 (forward) or -1.0 (backward).
  double get direction => data[3];
  set direction(double value) => data[3] = value;

  /// Whether to align velocity/rotation to the tangent of the path.
  bool get alignRotation => data[4] > 0.5;
  set alignRotation(bool value) => data[4] = value ? 1.0 : 0.0;

  /// The type of the path: 0 (Polyline), 1 (Quadratic Bezier), 2 (Cubic Bezier), 3 (Hermite).
  int get type => data[5].toInt();
  set type(int value) => data[5] = value.toDouble();

  // --- Points Access ---

  /// Gets the total number of points in this component.
  int get pointCount => (data.length - 6) ~/ 2;

  /// Sets the point at the specified index.
  void setPoint(int index, double x, double y) {
    if (index < 0 || index >= pointCount) return;
    data[6 + index * 2] = x;
    data[6 + index * 2 + 1] = y;
  }

  /// Gets the X coordinate of the point at the specified index.
  double getPointX(int index) {
    if (index < 0 || index >= pointCount) return 0.0;
    return data[6 + index * 2];
  }

  /// Gets the Y coordinate of the point at the specified index.
  double getPointY(int index) {
    if (index < 0 || index >= pointCount) return 0.0;
    return data[6 + index * 2 + 1];
  }

  /// Returns a sublist containing only the points data.
  /// Does not allocate new memory.
  Float32List get points => Float32List.sublistView(data, 6);
}
