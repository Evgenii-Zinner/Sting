import 'dart:typed_data';

/// A zero-allocation Parallax component using a Dart extension type over Float32List.
/// This allows layered rendering that scrolls at different rates relative to the viewport.
///
/// Memory layout (4 floats, 16 bytes total):
/// - Index 0: scrollFactorX (1.0 = normal scroll, 0.5 = scroll half speed, 0.0 = static)
/// - Index 1: scrollFactorY (1.0 = normal scroll, 0.5 = scroll half speed, 0.0 = static)
/// - Index 2: basePositionX (The original X position in the world)
/// - Index 3: basePositionY (The original Y position in the world)
extension type Parallax(Float32List data) {
  /// Creates a new Parallax component.
  Parallax.create(double scrollFactorX, double scrollFactorY, double basePositionX, double basePositionY)
    : this(Float32List(4)
        ..[0] = scrollFactorX
        ..[1] = scrollFactorY
        ..[2] = basePositionX
        ..[3] = basePositionY);

  /// Gets the X scroll factor.
  double get scrollFactorX => data[0];

  /// Sets the X scroll factor.
  set scrollFactorX(double value) => data[0] = value;

  /// Gets the Y scroll factor.
  double get scrollFactorY => data[1];

  /// Sets the Y scroll factor.
  set scrollFactorY(double value) => data[1] = value;

  /// Gets the base X position.
  double get basePositionX => data[2];

  /// Sets the base X position.
  set basePositionX(double value) => data[2] = value;

  /// Gets the base Y position.
  double get basePositionY => data[3];

  /// Sets the base Y position.
  set basePositionY(double value) => data[3] = value;
}
