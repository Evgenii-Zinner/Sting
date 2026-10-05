import 'dart:typed_data';

/// A flat FlowFieldFollower component using a Dart extension type over a Float32List.
/// Index 0: alignmentWeight (0.0 to 1.0)
/// Index 1: maxSpeed
/// Index 2: lookaheadDistance
extension type FlowFieldFollower(Float32List data) {
  /// Creates a new FlowFieldFollower component.
  FlowFieldFollower.create({
    double alignmentWeight = 0.5,
    double maxSpeed = 100.0,
    double lookaheadDistance = 20.0,
  }) : this(Float32List(3)
          ..[0] = alignmentWeight
          ..[1] = maxSpeed
          ..[2] = lookaheadDistance);

  /// Gets the alignment weight (0.0 to 1.0) towards the flow vector.
  double get alignmentWeight => data[0];

  /// Sets the alignment weight.
  set alignmentWeight(double value) => data[0] = value;

  /// Gets the max speed of the follower.
  double get maxSpeed => data[1];

  /// Sets the max speed.
  set maxSpeed(double value) => data[1] = value;

  /// Gets the lookahead distance along the current velocity vector to sample the field.
  double get lookaheadDistance => data[2];

  /// Sets the lookahead distance.
  set lookaheadDistance(double value) => data[2] = value;
}
