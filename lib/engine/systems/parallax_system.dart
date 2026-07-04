import '../ecs/query.dart';
import '../ecs/component_caste.dart';
import '../components/position.dart';
import '../components/viewport.dart';
import '../components/parallax.dart';

/// A zero-allocation system that updates the `Position` component of entities
/// based on their `Parallax` configuration and the current camera's `Viewport`.
class ParallaxSystem {
  final Query2<Position, Parallax> query;
  final ComponentCaste<Viewport>? viewportCaste;
  int activeCameraEntity;

  ParallaxSystem({
    required ComponentCaste<Position> positionCaste,
    required ComponentCaste<Parallax> parallaxCaste,
    this.viewportCaste,
    this.activeCameraEntity = -1,
  }) : query = Query2<Position, Parallax>(positionCaste, parallaxCaste);

  /// Updates the `Position` of all parallax entities.
  void update() {
    if (activeCameraEntity == -1 || viewportCaste == null) return;

    final viewport = viewportCaste!.get(activeCameraEntity);
    if (viewport == null) return;

    query.forEach((entity, position, parallax) {
      // The camera's viewport acts as the offset for rendering.
      // In our rendering system (e.g. SpriteRenderSystem), the canvas is translated by (-viewport.x, -viewport.y).
      // If a layer should scroll slower than the camera (e.g., scrollFactor = 0.5), it should move *with* the camera
      // to counteract the canvas translation partially.
      // Position = BasePosition + CameraPosition * (1.0 - scrollFactor)
      //
      // If scrollFactor = 1.0 (moves with camera exactly), Position = BasePosition. The canvas translation will move it normally.
      // If scrollFactor = 0.0 (static background, glued to screen), Position = BasePosition + CameraPosition.
      // The canvas translation will subtract CameraPosition, keeping it at BasePosition on the screen.

      position.x = parallax.basePositionX + (viewport.x * (1.0 - parallax.scrollFactorX));
      position.y = parallax.basePositionY + (viewport.y * (1.0 - parallax.scrollFactorY));
    });
  }
}
