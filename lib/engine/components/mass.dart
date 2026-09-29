import 'dart:typed_data';

/// A flat Mass component using a Dart extension type over a Float32List.
/// Index 0: mass value.
/// Index 1: inverseMass value.
/// Index 2: restitution (bounciness 0..1).
/// Index 3: friction (0..1).
extension type Mass(Float32List data) {
  /// Creates a new Mass component with the given [value], [restitution], and [friction].
  Mass.create(double value, {double restitution = 0.0, double friction = 0.0})
      : this(Float32List(4)
          ..[0] = value
          ..[1] = value > 0.0 ? 1.0 / value : 0.0
          ..[2] = restitution
          ..[3] = friction);

  /// Gets the mass value.
  double get value => data[0];

  /// Sets the mass value and updates inverse mass.
  set value(double val) {
    data[0] = val;
    data[1] = val > 0.0 ? 1.0 / val : 0.0;
  }

  /// Gets the inverse mass value.
  double get inverseMass => data[1];

  /// Gets the restitution value.
  double get restitution => data[2];

  /// Sets the restitution value.
  set restitution(double val) => data[2] = val;

  /// Gets the friction value.
  double get friction => data[3];

  /// Sets the friction value.
  set friction(double val) => data[3] = val;
}
