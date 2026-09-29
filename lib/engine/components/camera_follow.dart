import 'dart:typed_data';

/// A flat CameraFollow component using a Dart extension type over a ByteData.
/// Byte Offsets:
/// 0: targetEntity (Int32)
/// 4: deadzoneWidth (Float32)
/// 8: deadzoneHeight (Float32)
/// 12: lerpFactor (Float32)
/// 16: minX (Float32)
/// 20: minY (Float32)
/// 24: maxX (Float32)
/// 28: maxY (Float32)
extension type CameraFollow(ByteData data) {
  static const int sizeInBytes = 32;

  /// Creates a new CameraFollow component.
  CameraFollow.create({
    required int targetEntity,
    double deadzoneWidth = 0.0,
    double deadzoneHeight = 0.0,
    double lerpFactor = 1.0,
    double minX = double.nan,
    double minY = double.nan,
    double maxX = double.nan,
    double maxY = double.nan,
  }) : this(ByteData(sizeInBytes)
          ..setInt32(0, targetEntity, Endian.host)
          ..setFloat32(4, deadzoneWidth, Endian.host)
          ..setFloat32(8, deadzoneHeight, Endian.host)
          ..setFloat32(12, lerpFactor, Endian.host)
          ..setFloat32(16, minX, Endian.host)
          ..setFloat32(20, minY, Endian.host)
          ..setFloat32(24, maxX, Endian.host)
          ..setFloat32(28, maxY, Endian.host));

  int get targetEntity => data.getInt32(0, Endian.host);
  set targetEntity(int value) => data.setInt32(0, value, Endian.host);

  double get deadzoneWidth => data.getFloat32(4, Endian.host);
  set deadzoneWidth(double value) => data.setFloat32(4, value, Endian.host);

  double get deadzoneHeight => data.getFloat32(8, Endian.host);
  set deadzoneHeight(double value) => data.setFloat32(8, value, Endian.host);

  double get lerpFactor => data.getFloat32(12, Endian.host);
  set lerpFactor(double value) => data.setFloat32(12, value, Endian.host);

  double get minX => data.getFloat32(16, Endian.host);
  set minX(double value) => data.setFloat32(16, value, Endian.host);

  double get minY => data.getFloat32(20, Endian.host);
  set minY(double value) => data.setFloat32(20, value, Endian.host);

  double get maxX => data.getFloat32(24, Endian.host);
  set maxX(double value) => data.setFloat32(24, value, Endian.host);

  double get maxY => data.getFloat32(28, Endian.host);
  set maxY(double value) => data.setFloat32(28, value, Endian.host);
}
