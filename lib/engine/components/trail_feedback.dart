import 'dart:typed_data';

/// A zero-allocation component that reacts to values in a GroundTrailField.
extension type TrailFeedback(Float32List data) {
  /// Creates a new TrailFeedback component.
  TrailFeedback.create({
    required double baseFriction,
    required double boostedFriction,
    required double threshold,
    bool isOnTrail = false,
  }) : this(Float32List(4)
          ..[0] = baseFriction
          ..[1] = boostedFriction
          ..[2] = threshold
          ..[3] = isOnTrail ? 1.0 : 0.0);

  /// Gets the base friction.
  double get baseFriction => data[0];

  /// Sets the base friction.
  set baseFriction(double value) => data[0] = value;

  /// Gets the boosted friction.
  double get boostedFriction => data[1];

  /// Sets the boosted friction.
  set boostedFriction(double value) => data[1] = value;

  /// Gets the activation threshold.
  double get threshold => data[2];

  /// Sets the activation threshold.
  set threshold(double value) => data[2] = value;

  /// Returns true if currently on a trail that exceeds the threshold.
  bool get isOnTrail => data[3] > 0.5;

  /// Sets whether the entity is on a trail.
  set isOnTrail(bool value) => data[3] = value ? 1.0 : 0.0;
}
