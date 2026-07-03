import 'dart:typed_data';

/// A flat Mass component using a Dart extension type over a Float32List.
/// Index 0: mass value.
extension type Mass(Float32List data) {
  /// Creates a new Mass component with the given [value].
  Mass.create(double value) : this(Float32List(1)..[0] = value);

  /// Gets the mass value.
  double get value => data[0];

  /// Sets the mass value.
  set value(double val) => data[0] = val;
}
