import 'dart:typed_data';

/// A flat FlockingAgent component using a Dart extension type over a Float32List.
/// Index 0: neighborRadius
/// Index 1: separationWeight
/// Index 2: alignmentWeight
/// Index 3: cohesionWeight
/// Index 4: maxForce
extension type FlockingAgent(Float32List data) {
  /// Creates a new FlockingAgent component.
  FlockingAgent.create({
    double neighborRadius = 50.0,
    double separationWeight = 1.0,
    double alignmentWeight = 1.0,
    double cohesionWeight = 1.0,
    double maxForce = 10.0,
  }) : this(Float32List(5)
          ..[0] = neighborRadius
          ..[1] = separationWeight
          ..[2] = alignmentWeight
          ..[3] = cohesionWeight
          ..[4] = maxForce);

  double get neighborRadius => data[0];
  set neighborRadius(double value) => data[0] = value;

  double get separationWeight => data[1];
  set separationWeight(double value) => data[1] = value;

  double get alignmentWeight => data[2];
  set alignmentWeight(double value) => data[2] = value;

  double get cohesionWeight => data[3];
  set cohesionWeight(double value) => data[3] = value;

  double get maxForce => data[4];
  set maxForce(double value) => data[4] = value;
}
