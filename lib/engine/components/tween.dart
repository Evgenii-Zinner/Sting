import 'dart:typed_data';

/// Loop modes for tweens.
class TweenLoopMode {
  static const int once = 0;
  static const int pingPong = 1;
  static const int repeat = 2;
}

/// Easing types for tweens.
class TweenEasingType {
  static const int linear = 0;
  static const int easeInQuad = 1;
  static const int easeOutQuad = 2;
  static const int easeInOutQuad = 3;
  static const int easeInCubic = 4;
  static const int easeOutCubic = 5;
  static const int easeOutBounce = 6;
  static const int easeOutElastic = 7;
}

/// A flat Tween component using a Dart extension type over a ByteData.
/// Byte Offsets:
/// 0: targetProperty (Int32)
/// 4: startVal (Float32)
/// 8: endVal (Float32)
/// 12: currentVal (Float32)
/// 16: duration (Float32)
/// 20: elapsed (Float32)
/// 24: easingType (Int32)
/// 28: isComplete (Int32)
/// 32: loopMode (Int32)
extension type Tween(ByteData data) {
  static const int sizeInBytes = 36;

  /// Creates a new Tween component.
  Tween.create({
    required int targetProperty,
    required double startVal,
    required double endVal,
    required double duration,
    int easingType = TweenEasingType.linear,
    int loopMode = TweenLoopMode.once,
  }) : this(ByteData(sizeInBytes)
          ..setInt32(0, targetProperty, Endian.host)
          ..setFloat32(4, startVal, Endian.host)
          ..setFloat32(8, endVal, Endian.host)
          ..setFloat32(12, startVal, Endian.host)
          ..setFloat32(16, duration, Endian.host)
          ..setFloat32(20, 0.0, Endian.host)
          ..setInt32(24, easingType, Endian.host)
          ..setInt32(28, 0, Endian.host)
          ..setInt32(32, loopMode, Endian.host));

  int get targetProperty => data.getInt32(0, Endian.host);
  set targetProperty(int value) => data.setInt32(0, value, Endian.host);

  double get startVal => data.getFloat32(4, Endian.host);
  set startVal(double value) => data.setFloat32(4, value, Endian.host);

  double get endVal => data.getFloat32(8, Endian.host);
  set endVal(double value) => data.setFloat32(8, value, Endian.host);

  double get currentVal => data.getFloat32(12, Endian.host);
  set currentVal(double value) => data.setFloat32(12, value, Endian.host);

  double get duration => data.getFloat32(16, Endian.host);
  set duration(double value) => data.setFloat32(16, value, Endian.host);

  double get elapsed => data.getFloat32(20, Endian.host);
  set elapsed(double value) => data.setFloat32(20, value, Endian.host);

  int get easingType => data.getInt32(24, Endian.host);
  set easingType(int value) => data.setInt32(24, value, Endian.host);

  bool get isComplete => data.getInt32(28, Endian.host) != 0;
  set isComplete(bool value) => data.setInt32(28, value ? 1 : 0, Endian.host);

  int get loopMode => data.getInt32(32, Endian.host);
  set loopMode(int value) => data.setInt32(32, value, Endian.host);
}
