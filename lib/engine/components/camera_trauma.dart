import 'dart:typed_data';

/// A flat CameraTrauma component using a Dart extension type over a Float32List.
/// Index 0: trauma (0.0 to 1.0)
/// Index 1: decayRate
/// Index 2: maxTranslationX
/// Index 3: maxTranslationY
/// Index 4: maxRotation
/// Index 5: frequency
extension type CameraTrauma(Float32List data) {
  /// Creates a new CameraTrauma component.
  CameraTrauma.create({
    double trauma = 0.0,
    double decayRate = 1.0,
    double maxTranslationX = 0.0,
    double maxTranslationY = 0.0,
    double maxRotation = 0.0,
    double frequency = 10.0,
  }) : this(Float32List(6)
          ..[0] = trauma
          ..[1] = decayRate
          ..[2] = maxTranslationX
          ..[3] = maxTranslationY
          ..[4] = maxRotation
          ..[5] = frequency);

  /// Gets the current trauma (0.0 to 1.0).
  double get trauma => data[0];

  /// Sets the current trauma (clamped to 0.0 to 1.0).
  set trauma(double value) {
    if (value < 0.0) {
      data[0] = 0.0;
    } else if (value > 1.0) {
      data[0] = 1.0;
    } else {
      data[0] = value;
    }
  }

  /// Gets the decay rate.
  double get decayRate => data[1];

  /// Sets the decay rate.
  set decayRate(double value) => data[1] = value;

  /// Gets the max translation X.
  double get maxTranslationX => data[2];

  /// Sets the max translation X.
  set maxTranslationX(double value) => data[2] = value;

  /// Gets the max translation Y.
  double get maxTranslationY => data[3];

  /// Sets the max translation Y.
  set maxTranslationY(double value) => data[3] = value;

  /// Gets the max rotation.
  double get maxRotation => data[4];

  /// Sets the max rotation.
  set maxRotation(double value) => data[4] = value;

  /// Gets the frequency.
  double get frequency => data[5];

  /// Sets the frequency.
  set frequency(double value) => data[5] = value;

  /// Adds [amount] to the current trauma, clamping to 1.0.
  void addTrauma(double amount) {
    trauma = trauma + amount; // setter handles clamping
  }
}
