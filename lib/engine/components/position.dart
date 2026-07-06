import 'dart:typed_data';

/// A flat Position component using a Dart extension type over a Float32List.
/// Index 0: x, Index 1: y, Index 2: prevX, Index 3: prevY.
extension type Position(Float32List data) {
  /// Creates a new Position component with the given [x] and [y] coordinates.
  Position.create(double x, double y)
      : this(Float32List(4)
          ..[0] = x
          ..[1] = y
          ..[2] = x
          ..[3] = y);

  /// Gets the x coordinate.
  double get x => data[0];

  /// Sets the x coordinate.
  set x(double value) => data[0] = value;

  /// Gets the y coordinate.
  double get y => data[1];

  /// Sets the y coordinate.
  set y(double value) => data[1] = value;

  /// Gets the previous x coordinate.
  double get prevX => data[2];

  /// Sets the previous x coordinate.
  set prevX(double value) => data[2] = value;

  /// Gets the previous y coordinate.
  double get prevY => data[3];

  /// Sets the previous y coordinate.
  set prevY(double value) => data[3] = value;
}
