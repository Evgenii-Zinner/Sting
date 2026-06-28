import 'dart:typed_data';

/// A flat SpriteAnimation component using a Dart extension type over a Float32List.
/// Index 0: currentFrameIndex (stored as float)
/// Index 1: frameDuration
/// Index 2: elapsedTime
/// Index 3: frameCount (stored as float)
extension type SpriteAnimation(Float32List data) {
  /// Creates a new SpriteAnimation component with the given [frameDuration] and [frameCount].
  SpriteAnimation.create(double frameDuration, int frameCount)
      : this(Float32List(4)
          ..[0] = 0.0
          ..[1] = frameDuration
          ..[2] = 0.0
          ..[3] = frameCount.toDouble());

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
}
