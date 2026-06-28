import 'dart:typed_data';

/// A flat CircleCollider component using a Dart extension type over a Float32List.
/// Index 0: radius.
extension type CircleCollider(Float32List data) {
  /// Creates a new CircleCollider component with the given [radius].
  CircleCollider.create(double radius) : this(Float32List(1)..[0] = radius);

  /// Gets the radius.
  double get radius => data[0];

  /// Sets the radius.
  set radius(double value) => data[0] = value;
}
