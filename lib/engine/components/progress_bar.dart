import 'dart:typed_data';

/// A flat ProgressBar component using a Dart extension type over a Float32List.
///
/// Data layout (16 floats):
/// - Index 0: currentValue
/// - Index 1: maxValue
/// - Index 2: visualValue (smoothly interpolates towards currentValue for trailing ghost/damage bar)
/// - Index 3: width
/// - Index 4: height
/// - Index 5: borderWidth
/// - Index 6: borderRadius
/// - Index 7: fillColorHex (stored as double from int color, e.g. 0xFF00E5FF)
/// - Index 8: backgroundColorHex (stored as double from int color, e.g. 0xFF0A0C14)
/// - Index 9: borderColorHex (stored as double from int color, e.g. 0xFF00B0FF)
/// - Index 10: ghostColorHex (trailing damage bar color, e.g. 0xFFFF5252)
/// - Index 11: segments (double cast from int: 0.0 for continuous, >1.0 for segmented pips/notches)
/// - Index 12: isWorldSpace (1.0 = anchored to entity's Position in world, 0.0 = screen HUD)
/// - Index 13: offsetX
/// - Index 14: offsetY
/// - Index 15: catchUpSpeed (speed of visualValue interpolation, default 5.0)
extension type ProgressBar(Float32List data) {
  /// Creates a new ProgressBar component with the given configuration.
  static ProgressBar create({
    double currentValue = 100.0,
    double maxValue = 100.0,
    double width = 100.0,
    double height = 10.0,
    double borderWidth = 1.0,
    double borderRadius = 2.0,
    int fillColorHex = 0xFF00E5FF,
    int backgroundColorHex = 0xFF0A0C14,
    int borderColorHex = 0xFF00B0FF,
    int ghostColorHex = 0xFFFF5252,
    double segments = 0.0,
    double isWorldSpace = 1.0,
    double offsetX = 0.0,
    double offsetY = 0.0,
    double catchUpSpeed = 5.0,
  }) {
    final pb = ProgressBar(Float32List(16));
    pb.currentValue = currentValue;
    pb.maxValue = maxValue;
    pb.visualValue = currentValue; // initial visual value matches current value
    pb.width = width;
    pb.height = height;
    pb.borderWidth = borderWidth;
    pb.borderRadius = borderRadius;
    pb.fillColorHex = fillColorHex.toDouble();
    pb.backgroundColorHex = backgroundColorHex.toDouble();
    pb.borderColorHex = borderColorHex.toDouble();
    pb.ghostColorHex = ghostColorHex.toDouble();
    pb.segments = segments;
    pb.isWorldSpace = isWorldSpace;
    pb.offsetX = offsetX;
    pb.offsetY = offsetY;
    pb.catchUpSpeed = catchUpSpeed;
    return pb;
  }

  /// Current resource or stat value.
  double get currentValue => data[0];
  set currentValue(double value) => data[0] = value;

  /// Maximum resource or stat capacity.
  double get maxValue => data[1];
  set maxValue(double value) => data[1] = value;

  /// Smoothly interpolated trailing value for ghost damage indicator.
  double get visualValue => data[2];
  set visualValue(double value) => data[2] = value;

  /// Bar width in pixels.
  double get width => data[3];
  set width(double value) => data[3] = value;

  /// Bar height in pixels.
  double get height => data[4];
  set height(double value) => data[4] = value;

  /// Border outline width.
  double get borderWidth => data[5];
  set borderWidth(double value) => data[5] = value;

  /// Corner radius for rounded corners.
  double get borderRadius => data[6];
  set borderRadius(double value) => data[6] = value;

  /// Foreground fill color hex.
  double get fillColorHex => data[7];
  set fillColorHex(double value) => data[7] = value;

  /// Background color hex.
  double get backgroundColorHex => data[8];
  set backgroundColorHex(double value) => data[8] = value;

  /// Border outline color hex.
  double get borderColorHex => data[9];
  set borderColorHex(double value) => data[9] = value;

  /// Trailing ghost damage bar color hex.
  double get ghostColorHex => data[10];
  set ghostColorHex(double value) => data[10] = value;

  /// Number of segmented pips (0.0 for continuous).
  double get segments => data[11];
  set segments(double value) => data[11] = value;

  /// Whether anchored in world space (1.0) or screen HUD (0.0).
  double get isWorldSpace => data[12];
  set isWorldSpace(double value) => data[12] = value;

  /// Horizontal offset from origin or entity position.
  double get offsetX => data[13];
  set offsetX(double value) => data[13] = value;

  /// Vertical offset from origin or entity position.
  double get offsetY => data[14];
  set offsetY(double value) => data[14] = value;

  /// Interpolation rate for trailing visual value catch-up.
  double get catchUpSpeed => data[15];
  set catchUpSpeed(double value) => data[15] = value;

  /// Helper getter for the ratio of currentValue to maxValue, clamped between 0 and 1.
  double get ratio =>
      (currentValue / (maxValue > 0 ? maxValue : 1.0)).clamp(0.0, 1.0);
}
