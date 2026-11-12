import 'dart:typed_data';
import 'dart:ui';
import '../ecs/component_storage.dart';

/// A flat Viewport component using a Dart extension type over a Float32List.
/// Index 0: x, Index 1: y, Index 2: zoom, Index 3: angle.
extension type Viewport(Float32List data) {
  /// Creates a new Viewport component with the given [x], [y], [zoom], and [angle].
  Viewport.create(
      [double x = 0.0, double y = 0.0, double zoom = 1.0, double angle = 0.0])
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

  /// Snaps a logical coordinate or scalar to the physical pixel grid at [scale]
  /// to eliminate texture shimmering and fractional subpixel jitter.
  static double snapToPixel(double value, [double scale = 1.0]) =>
      (value * scale).roundToDouble() / scale;

  /// Applies camera transformation (zoom scale and pixel-snapped translation) to [canvas].
  void applyTransform(Canvas canvas, [double scale = 1.0]) {
    canvas.scale(zoom, zoom);
    final snappedVx = snapToPixel(x, scale);
    final snappedVy = snapToPixel(y, scale);
    canvas.translate(-snappedVx, -snappedVy);
  }

  /// Attempts to apply the active camera viewport transform to [canvas].
  ///
  /// Returns `true` if a viewport was found and `canvas.save()` was called,
  /// requiring a matching `canvas.restore()` after rendering.
  static bool applyCamera(
    Canvas canvas,
    int activeCameraEntity,
    ComponentStorage<Viewport>? viewportCaste, [
    double scale = 1.0,
  ]) {
    if (activeCameraEntity != -1 && viewportCaste != null) {
      final viewport = viewportCaste.get(activeCameraEntity);
      if (viewport != null) {
        canvas.save();
        viewport.applyTransform(canvas, scale);
        return true;
      }
    }
    return false;
  }
}
