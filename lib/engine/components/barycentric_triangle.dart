import 'dart:typed_data';

/// A Barycentric Priority Triangle UI component.
/// Implemented as a Dart 3 extension type over a `Float32List` to ensure
/// zero per-frame memory allocations.
///
/// Indices mapping:
/// 0: centerX
/// 1: centerY
/// 2: radius (from center to corners)
/// 3: rotation (angle in radians)
/// 4: weightA (normalized 0.0 to 1.0)
/// 5: weightB (normalized 0.0 to 1.0)
/// 6: weightC (normalized 0.0 to 1.0)
/// 7: puckX
/// 8: puckY
/// 9: isDragging (1.0 = true, 0.0 = false)
/// 10: cornerAColorHex (32-bit ARGB float)
/// 11: cornerBColorHex (32-bit ARGB float)
/// 12: cornerCColorHex (32-bit ARGB float)
/// 13: puckColorHex (32-bit ARGB float)
/// 14: strokeWidth
/// 15: padding/reserved
extension type BarycentricTriangle(Float32List _data) {
  /// Creates a new BarycentricTriangle.
  factory BarycentricTriangle.create({
    required double centerX,
    required double centerY,
    required double radius,
    double rotation = 0.0,
    double weightA = 0.3333333,
    double weightB = 0.3333333,
    double weightC = 0.3333333,
    double puckX = 0.0,
    double puckY = 0.0,
    double cornerAColorHex = 4294901760.0, // 0xFFFF0000 (Red)
    double cornerBColorHex = 4278255360.0, // 0xFF00FF00 (Green)
    double cornerCColorHex = 4278190335.0, // 0xFF0000FF (Blue)
    double puckColorHex = 4294967295.0, // 0xFFFFFFFF (White)
    double strokeWidth = 2.0,
  }) {
    final data = Float32List(16);
    data[0] = centerX;
    data[1] = centerY;
    data[2] = radius;
    data[3] = rotation;
    data[4] = weightA;
    data[5] = weightB;
    data[6] = weightC;
    data[7] = puckX;
    data[8] = puckY;
    data[9] = 0.0; // isDragging
    data[10] = cornerAColorHex;
    data[11] = cornerBColorHex;
    data[12] = cornerCColorHex;
    data[13] = puckColorHex;
    data[14] = strokeWidth;
    data[15] = 0.0;
    return BarycentricTriangle(data);
  }

  double get centerX => _data[0];
  set centerX(double value) => _data[0] = value;

  double get centerY => _data[1];
  set centerY(double value) => _data[1] = value;

  double get radius => _data[2];
  set radius(double value) => _data[2] = value;

  double get rotation => _data[3];
  set rotation(double value) => _data[3] = value;

  double get weightA => _data[4];
  set weightA(double value) => _data[4] = value;

  double get weightB => _data[5];
  set weightB(double value) => _data[5] = value;

  double get weightC => _data[6];
  set weightC(double value) => _data[6] = value;

  double get puckX => _data[7];
  set puckX(double value) => _data[7] = value;

  double get puckY => _data[8];
  set puckY(double value) => _data[8] = value;

  double get isDragging => _data[9];
  set isDragging(double value) => _data[9] = value;

  double get cornerAColorHex => _data[10];
  set cornerAColorHex(double value) => _data[10] = value;

  double get cornerBColorHex => _data[11];
  set cornerBColorHex(double value) => _data[11] = value;

  double get cornerCColorHex => _data[12];
  set cornerCColorHex(double value) => _data[12] = value;

  double get puckColorHex => _data[13];
  set puckColorHex(double value) => _data[13] = value;

  double get strokeWidth => _data[14];
  set strokeWidth(double value) => _data[14] = value;
}
