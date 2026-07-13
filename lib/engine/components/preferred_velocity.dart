import 'dart:typed_data';

/// A flat PreferredVelocity component using a Dart extension type over a Float32List.
/// Used for steering behaviors and collision avoidance (RVO/ORCA) to denote
/// the desired direction of travel before collision penalties are applied.
/// Index 0: dx, Index 1: dy.
extension type PreferredVelocity(Float32List data) {
  /// Creates a new PreferredVelocity component with the given [dx] and [dy].
  PreferredVelocity.create(double dx, double dy)
      : this(Float32List(2)
          ..[0] = dx
          ..[1] = dy);

  /// Gets the dx value.
  double get dx => data[0];

  /// Sets the dx value.
  set dx(double value) => data[0] = value;

  /// Gets the dy value.
  double get dy => data[1];

  /// Sets the dy value.
  set dy(double value) => data[1] = value;
}
