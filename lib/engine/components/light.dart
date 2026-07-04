import 'dart:typed_data';

/// A Data-Oriented 2D Light component.
///
/// Stored in a flat Float32List:
/// - index 0: radius (pixels)
/// - index 1: intensity (0.0 to 1.0)
/// - index 2: red (0.0 to 1.0)
/// - index 3: green (0.0 to 1.0)
/// - index 4: blue (0.0 to 1.0)
/// - index 5: active (1.0 = true, 0.0 = false)
extension type Light(Float32List _data) implements Float32List {
  static const int componentSize = 6;

  Light.create({
    required double radius,
    double intensity = 1.0,
    double r = 1.0,
    double g = 1.0,
    double b = 1.0,
    bool active = true,
  }) : _data = Float32List(componentSize) {
    this.radius = radius;
    this.intensity = intensity;
    this.r = r;
    this.g = g;
    this.b = b;
    this.active = active;
  }

  double get radius => _data[0];
  set radius(double value) => _data[0] = value;

  double get intensity => _data[1];
  set intensity(double value) => _data[1] = value;

  double get r => _data[2];
  set r(double value) => _data[2] = value;

  double get g => _data[3];
  set g(double value) => _data[3] = value;

  double get b => _data[4];
  set b(double value) => _data[4] = value;

  bool get active => _data[5] > 0.0;
  set active(bool value) => _data[5] = value ? 1.0 : 0.0;
}
