import 'dart:typed_data';

/// A zero-allocation component that emits values into a continuous grid buffer.
extension type FieldEmitter(Float32List data) {
  /// Creates a new FieldEmitter.
  /// [falloffType]: 0 for Bilinear, 1 for Gaussian, 2 for Flat.
  FieldEmitter.create({
    int targetChannel = 0,
    double emissionRate = 1.0,
    double radius = 1.0,
    int falloffType = 0,
    bool isActive = true,
  }) : this(Float32List(5)
          ..[0] = targetChannel.toDouble()
          ..[1] = emissionRate
          ..[2] = radius
          ..[3] = falloffType.toDouble()
          ..[4] = isActive ? 1.0 : 0.0);

  int get targetChannel => data[0].toInt();
  set targetChannel(int value) => data[0] = value.toDouble();

  double get emissionRate => data[1];
  set emissionRate(double value) => data[1] = value;

  double get radius => data[2];
  set radius(double value) => data[2] = value;

  int get falloffType => data[3].toInt();
  set falloffType(int value) => data[3] = value.toDouble();

  bool get isActive => data[4] > 0.5;
  set isActive(bool value) => data[4] = value ? 1.0 : 0.0;
}
