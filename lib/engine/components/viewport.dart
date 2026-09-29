import 'dart:typed_data';

/// A flat Viewport component using a Dart extension type over a Float32List.
/// Index 0: x, Index 1: y, Index 2: zoom, Index 3: angle.
extension type Viewport(Float32List data) {
  /// Creates a new Viewport component with the given [x], [y], [zoom], and [angle].
  Viewport.create([double x = 0.0, double y = 0.0, double zoom = 1.0, double angle = 0.0])
      : this(Float32List(4)
          ..[0] = x
          ..[1] = y
          ..[2] = zoom
          ..[3] = angle);

  /// Gets the x coordinate of the camera.
  double get x => data[0];

  /// Sets the x coordinate of the camera.
  set x(double value) => data[0] = value;

  /// Gets the y coordinate of the camera.
  double get y => data[1];

  /// Sets the y coordinate of the camera.
  set y(double value) => data[1] = value;

  /// Gets the zoom level of the camera.
  double get zoom => data[2];

  /// Sets the zoom level of the camera.
  set zoom(double value) => data[2] = value;

  /// Gets the angle of the camera in radians.
  double get angle => data[3];

  /// Sets the angle of the camera in radians.
  set angle(double value) => data[3] = value;
}
