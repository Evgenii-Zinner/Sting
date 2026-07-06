import 'dart:typed_data';

/// A flat BoundingBox component using a Dart extension type over a Float32List.
/// Index 0: width, Index 1: height.
extension type BoundingBox(Float32List data) {
  /// Creates a new BoundingBox component with the given [width] and [height].
  BoundingBox.create(double width, double height)
      : this(Float32List(2)
          ..[0] = width
          ..[1] = height);

  /// Gets the width.
  double get width => data[0];

  /// Sets the width.
  set width(double value) => data[0] = value;

  /// Gets the height.
  double get height => data[1];

  /// Sets the height.
  set height(double value) => data[1] = value;
}
