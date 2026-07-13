import 'dart:typed_data';

/// A flat Steering component using a Dart extension type over a Float32List.
/// Used to calculate continuous steering forces.
/// Index 0: targetX
/// Index 1: targetY
/// Index 2: maxSpeed
/// Index 3: maxForce
/// Index 4: behavior (0.0 = Seek, 1.0 = Flee, 2.0 = Arrive)
/// Index 5: decelerationRadius (for Arrive behavior)
extension type Steering(Float32List data) {
  /// Creates a new Steering component.
  Steering.create({
    double targetX = 0.0,
    double targetY = 0.0,
    double maxSpeed = 100.0,
    double maxForce = 10.0,
    double behavior = 0.0,
    double decelerationRadius = 50.0,
  }) : this(Float32List(6)
          ..[0] = targetX
          ..[1] = targetY
          ..[2] = maxSpeed
          ..[3] = maxForce
          ..[4] = behavior
          ..[5] = decelerationRadius);

  double get targetX => data[0];
  set targetX(double value) => data[0] = value;

  double get targetY => data[1];
  set targetY(double value) => data[1] = value;

  double get maxSpeed => data[2];
  set maxSpeed(double value) => data[2] = value;

  double get maxForce => data[3];
  set maxForce(double value) => data[3] = value;

  /// Behavior type:
  /// 0.0 = Seek
  /// 1.0 = Flee
  /// 2.0 = Arrive
  double get behavior => data[4];
  set behavior(double value) => data[4] = value;

  double get decelerationRadius => data[5];
  set decelerationRadius(double value) => data[5] = value;

  static const double behaviorSeek = 0.0;
  static const double behaviorFlee = 1.0;
  static const double behaviorArrive = 2.0;
}
