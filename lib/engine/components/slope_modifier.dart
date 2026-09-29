import 'dart:typed_data';

/// A component that modifies entity movement based on slope kinematics.
/// Represented as a flat Float32List with 8 elements.
extension type SlopeModifier(Float32List data) {
  /// Creates a SlopeModifier with initial configuration.
  SlopeModifier.create({
    double uphillResistance = 1.0,
    double downhillBoost = 0.5,
    double maxClimbableSlope = 1.0,
    double gravityPull = 9.8,
    double slideThreshold = 0.3,
  }) : this(Float32List(8)
          ..[0] = uphillResistance
          ..[1] = downhillBoost
          ..[2] = maxClimbableSlope
          ..[3] = gravityPull
          ..[4] = slideThreshold
          ..[5] = 0.0 // currentSlopeGrade
          ..[6] = 0.0 // currentSlopeAngle
          ..[7] = 0.0 // isStuckOrSliding
        );

  double get uphillResistance => data[0];
  set uphillResistance(double value) => data[0] = value;

  double get downhillBoost => data[1];
  set downhillBoost(double value) => data[1] = value;

  double get maxClimbableSlope => data[2];
  set maxClimbableSlope(double value) => data[2] = value;

  double get gravityPull => data[3];
  set gravityPull(double value) => data[3] = value;

  double get slideThreshold => data[4];
  set slideThreshold(double value) => data[4] = value;

  double get currentSlopeGrade => data[5];
  set currentSlopeGrade(double value) => data[5] = value;

  double get currentSlopeAngle => data[6];
  set currentSlopeAngle(double value) => data[6] = value;

  double get isStuckOrSliding => data[7];
  set isStuckOrSliding(double value) => data[7] = value;
}
