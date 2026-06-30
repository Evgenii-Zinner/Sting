import 'dart:typed_data';

/// A flat Sprite component using a Dart extension type over ByteData.
/// This allows us to pack floats (rect, transform) and an int (color)
/// into a contiguous chunk of memory to avoid GC allocations during updates.
///
/// Memory layout (36 bytes total):
/// - Rect (left, top, right, bottom) : 4 x 4 bytes = 16 bytes (offsets 0 - 15)
/// - RSTransform (scos, ssin, tx, ty) : 4 x 4 bytes = 16 bytes (offsets 16 - 31)
/// - Color : 1 x 4 bytes = 4 bytes (offset 32)
extension type Sprite(ByteData data) {
  /// Creates a new Sprite component initialized to zero/transparent.
  static Sprite create() {
    final s = Sprite(ByteData(36));
    s.transformScos = 1.0;
    s.color = 0xFFFFFFFF;
    s.rectRight = 32.0;
    s.rectBottom = 32.0;
    return s;
  }

  // --- Rect ---

  double get rectLeft => data.getFloat32(0, Endian.host);
  set rectLeft(double value) => data.setFloat32(0, value, Endian.host);

  double get rectTop => data.getFloat32(4, Endian.host);
  set rectTop(double value) => data.setFloat32(4, value, Endian.host);

  double get rectRight => data.getFloat32(8, Endian.host);
  set rectRight(double value) => data.setFloat32(8, value, Endian.host);

  double get rectBottom => data.getFloat32(12, Endian.host);
  set rectBottom(double value) => data.setFloat32(12, value, Endian.host);

  // --- RSTransform ---

  double get transformScos => data.getFloat32(16, Endian.host);
  set transformScos(double value) => data.setFloat32(16, value, Endian.host);

  double get transformSsin => data.getFloat32(20, Endian.host);
  set transformSsin(double value) => data.setFloat32(20, value, Endian.host);

  double get transformTx => data.getFloat32(24, Endian.host);
  set transformTx(double value) => data.setFloat32(24, value, Endian.host);

  double get transformTy => data.getFloat32(28, Endian.host);
  set transformTy(double value) => data.setFloat32(28, value, Endian.host);

  // --- Color ---

  int get color => data.getUint32(32, Endian.host);
  set color(int value) => data.setUint32(32, value, Endian.host);
}
