import 'dart:typed_data';

/// A flat RadarDisplay component using a Dart extension type over a Float32List.
/// Layout (10 floats):
/// Index 0: screenX, 1: screenY, 2: radius
/// Index 3: worldRange, 4: sweepSpeed, 5: sweepAngle
/// Index 6: backgroundColorHex (as Uint32)
/// Index 7: radarColorHex (as Uint32)
/// Index 8: blipColorHex (as Uint32)
/// Index 9: isCircular (1.0 = circular, 0.0 = square)
extension type RadarDisplay(Float32List data) {
  /// Creates a new RadarDisplay component.
  factory RadarDisplay.create(
    double screenX,
    double screenY,
    double radius,
    double worldRange,
    double sweepSpeed,
    double sweepAngle,
    int backgroundColorHex,
    int radarColorHex,
    int blipColorHex,
    double isCircular,
  ) {
    final radar = RadarDisplay(Float32List(10));
    radar.screenX = screenX;
    radar.screenY = screenY;
    radar.radius = radius;
    radar.worldRange = worldRange;
    radar.sweepSpeed = sweepSpeed;
    radar.sweepAngle = sweepAngle;
    radar.backgroundColorHex = backgroundColorHex;
    radar.radarColorHex = radarColorHex;
    radar.blipColorHex = blipColorHex;
    radar.isCircular = isCircular;
    return radar;
  }

  /// Gets the screen X coordinate.
  double get screenX => data[0];
  set screenX(double value) => data[0] = value;

  /// Gets the screen Y coordinate.
  double get screenY => data[1];
  set screenY(double value) => data[1] = value;

  /// Gets the radar radius (screen size).
  double get radius => data[2];
  set radius(double value) => data[2] = value;

  /// Gets the maximum world distance scanned.
  double get worldRange => data[3];
  set worldRange(double value) => data[3] = value;

  /// Gets the sweep speed (radians per second).
  double get sweepSpeed => data[4];
  set sweepSpeed(double value) => data[4] = value;

  /// Gets the current sweep angle.
  double get sweepAngle => data[5];
  set sweepAngle(double value) => data[5] = value;

  /// Gets the background color in ARGB hex.
  int get backgroundColorHex => data.buffer.asUint32List(data.offsetInBytes, 10)[6];
  set backgroundColorHex(int value) => data.buffer.asUint32List(data.offsetInBytes, 10)[6] = value;

  /// Gets the radar grid/rings color in ARGB hex.
  int get radarColorHex => data.buffer.asUint32List(data.offsetInBytes, 10)[7];
  set radarColorHex(int value) => data.buffer.asUint32List(data.offsetInBytes, 10)[7] = value;

  /// Gets the blip (entity pip) color in ARGB hex.
  int get blipColorHex => data.buffer.asUint32List(data.offsetInBytes, 10)[8];
  set blipColorHex(int value) => data.buffer.asUint32List(data.offsetInBytes, 10)[8] = value;

  /// Gets whether the radar is circular (1.0) or square (0.0).
  double get isCircular => data[9];
  set isCircular(double value) => data[9] = value;
}
