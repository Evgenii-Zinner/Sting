import 'dart:typed_data';

/// A flat SpriteAnimation component using a Dart extension type over a Float32List.
/// Index 0: currentFrameIndex (stored as float)
/// Index 1: frameDuration
/// Index 2: elapsedTime
/// Index 3: frameCount (stored as float)
/// Index 4: frameWidth
/// Index 5: frameHeight
/// Index 6: startX
/// Index 7: startY
extension type SpriteAnimation(Float32List data) {
  /// Creates a new SpriteAnimation component with the given parameters.
  SpriteAnimation.create(
    double frameDuration,
    int frameCount, {
    double frameWidth = 0.0,
    double frameHeight = 0.0,
    double startX = 0.0,
    double startY = 0.0,
  }) : this(Float32List(8)
          ..[0] = 0.0
          ..[1] = frameDuration
          ..[2] = 0.0
          ..[3] = frameCount.toDouble()
          ..[4] = frameWidth
          ..[5] = frameHeight
          ..[6] = startX
          ..[7] = startY);

  /// Gets the current frame index.
  int get currentFrameIndex => data[0].toInt();

  /// Sets the current frame index.
  set currentFrameIndex(int value) => data[0] = value.toDouble();

  /// Gets the frame duration.
  double get frameDuration => data[1];

  /// Sets the frame duration.
  set frameDuration(double value) => data[1] = value;

  /// Gets the elapsed time.
  double get elapsedTime => data[2];

  /// Sets the elapsed time.
  set elapsedTime(double value) => data[2] = value;

  /// Gets the total frame count.
  int get frameCount => data[3].toInt();

  /// Sets the total frame count.
  set frameCount(int value) => data[3] = value.toDouble();

  /// Gets the frame width.
  double get frameWidth => data[4];

  /// Sets the frame width.
  set frameWidth(double value) => data[4] = value;

  /// Gets the frame height.
  double get frameHeight => data[5];

  /// Sets the frame height.
  set frameHeight(double value) => data[5] = value;

  /// Gets the start X coordinate on the sprite sheet.
  double get startX => data[6];

  /// Sets the start X coordinate on the sprite sheet.
  set startX(double value) => data[6] = value;

  /// Gets the start Y coordinate on the sprite sheet.
  double get startY => data[7];

  /// Sets the start Y coordinate on the sprite sheet.
  set startY(double value) => data[7] = value;
}
