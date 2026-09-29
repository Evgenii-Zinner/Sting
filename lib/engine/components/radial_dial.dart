import 'dart:typed_data';

/// A Sci-Fi Radial Intent Dial UI component.
/// Implemented as a Dart 3 extension type over a `Float32List` to ensure
/// zero per-frame memory allocations.
///
/// Indices mapping:
/// 0: centerX
/// 1: centerY
/// 2: outerRadius
/// 3: innerRadius
/// 4: currentValue (normalized 0.0 to 1.0)
/// 5: minValue
/// 6: maxValue
/// 7: startAngle
/// 8: endAngle
/// 9: trackColorHex
/// 10: fillColorHex
/// 11: handleColorHex
/// 12: isDragging (1.0 = true, 0.0 = false)
/// 13: segments (0.0 = smooth, >1.0 = segmented tick notches)
extension type RadialDial(Float32List _data) {
  /// Creates a new RadialDial.
  factory RadialDial.create({
    required double centerX,
    required double centerY,
    required double outerRadius,
    required double innerRadius,
    double currentValue = 0.0,
    double minValue = 0.0,
    double maxValue = 1.0,
    double startAngle = 0.0,
    double endAngle = 6.28318530718, // 2 * pi
    double trackColorHex = 4281545523.0, // 0xFF333333
    double fillColorHex = 4278239231.0, // 0xFF00BFFF
    double handleColorHex = 4294967295.0, // 0xFFFFFFFF
    double segments = 0.0,
  }) {
    final data = Float32List(14);
    data[0] = centerX;
    data[1] = centerY;
    data[2] = outerRadius;
    data[3] = innerRadius;
    data[4] = currentValue;
    data[5] = minValue;
    data[6] = maxValue;
    data[7] = startAngle;
    data[8] = endAngle;
    data[9] = trackColorHex;
    data[10] = fillColorHex;
    data[11] = handleColorHex;
    data[12] = 0.0; // isDragging
    data[13] = segments;
    return RadialDial(data);
  }

  double get centerX => _data[0];
  set centerX(double value) => _data[0] = value;

  double get centerY => _data[1];
  set centerY(double value) => _data[1] = value;

  double get outerRadius => _data[2];
  set outerRadius(double value) => _data[2] = value;

  double get innerRadius => _data[3];
  set innerRadius(double value) => _data[3] = value;

  double get currentValue => _data[4];
  set currentValue(double value) => _data[4] = value;

  double get minValue => _data[5];
  set minValue(double value) => _data[5] = value;

  double get maxValue => _data[6];
  set maxValue(double value) => _data[6] = value;

  double get startAngle => _data[7];
  set startAngle(double value) => _data[7] = value;

  double get endAngle => _data[8];
  set endAngle(double value) => _data[8] = value;

  double get trackColorHex => _data[9];
  set trackColorHex(double value) => _data[9] = value;

  double get fillColorHex => _data[10];
  set fillColorHex(double value) => _data[10] = value;

  double get handleColorHex => _data[11];
  set handleColorHex(double value) => _data[11] = value;

  double get isDragging => _data[12];
  set isDragging(double value) => _data[12] = value;

  double get segments => _data[13];
  set segments(double value) => _data[13] = value;

  double get scaledValue => minValue + currentValue * (maxValue - minValue);
}
