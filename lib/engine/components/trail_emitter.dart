import 'dart:typed_data';

/// A zero-allocation component that emits trail deposition onto a GroundTrailField.
extension type TrailEmitter(Float32List data) {
  /// Creates a new TrailEmitter with the given deposition rate and active state.
  TrailEmitter.create(double depositionRate, {bool isActive = true})
      : this(Float32List(2)
          ..[0] = depositionRate
          ..[1] = isActive ? 1.0 : 0.0);

  /// Gets the deposition rate (amount added to the trail field per second).
  double get depositionRate => data[0];

  /// Sets the deposition rate.
  set depositionRate(double value) => data[0] = value;

  /// Returns true if the emitter is active (1.0).
  bool get isActive => data[1] > 0.5;

  /// Sets whether the emitter is active.
  set isActive(bool value) => data[1] = value ? 1.0 : 0.0;
}
