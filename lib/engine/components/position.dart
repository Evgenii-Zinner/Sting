import 'dart:typed_data';

/// A flat Position component using a Dart extension type over a Float32List.
/// Index 0: x, Index 1: y.
extension type Position(Float32List data) {
  /// Creates a new Position component with the given [x] and [y] coordinates.
  Position.create(double x, double y)
      : this(Float32List(2)
          ..[0] = x
          ..[1] = y);

  /// Gets the x coordinate.
  double get x => data[0];

  /// Sets the x coordinate.
  set x(double value) => data[0] = value;

  /// Gets the y coordinate.
  double get y => data[1];

  /// Sets the y coordinate.
  set y(double value) => data[1] = value;
}
