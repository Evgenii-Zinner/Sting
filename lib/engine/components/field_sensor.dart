import 'dart:typed_data';

/// A component for sensing scalar fields (like GroundTrailField or heatmaps).
/// It evaluates the field value and gradient at the entity's position.
///
/// Memory layout (Float32List of size 6):
/// - Index 0: targetChannel (float cast to int)
/// - Index 1: sensitivity (positive = seek peak/heat, negative = flee/avoid)
/// - Index 2: sensorRadius (distance used for central difference gradient)
/// - Index 3: lastSampledValue
/// - Index 4: lastGradientX
/// - Index 5: lastGradientY
extension type FieldSensor(Float32List data) {
  /// Creates a FieldSensor component.
  FieldSensor.create({
    int targetChannel = 0,
    double sensitivity = 1.0,
    double sensorRadius = 1.0,
  }) : this(Float32List(6)
          ..[0] = targetChannel.toDouble()
          ..[1] = sensitivity
          ..[2] = sensorRadius
          ..[3] = 0.0
          ..[4] = 0.0
          ..[5] = 0.0);

  /// The channel/entity ID of the field to sample from.
  int get targetChannel => data[0].toInt();
  set targetChannel(int value) => data[0] = value.toDouble();

  /// Sensitivity to the field. Positive seeks higher values, negative avoids.
  double get sensitivity => data[1];
  set sensitivity(double value) => data[1] = value;

  /// The distance from the center used to sample for the gradient computation.
  double get sensorRadius => data[2];
  set sensorRadius(double value) => data[2] = value;

  /// The scalar value at the entity's position from the last update.
  double get lastSampledValue => data[3];
  set lastSampledValue(double value) => data[3] = value;

  /// The X component of the field gradient from the last update.
  double get lastGradientX => data[4];
  set lastGradientX(double value) => data[4] = value;

  /// The Y component of the field gradient from the last update.
  double get lastGradientY => data[5];
  set lastGradientY(double value) => data[5] = value;
}
