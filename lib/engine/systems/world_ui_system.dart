import '../ecs/component_caste.dart';
import '../components/position.dart';
import '../components/viewport.dart';
import '../components/world_ui.dart';
import '../components/complex_ui.dart';

/// Translates entity world coordinates to viewport screen-space coordinates,
/// updating target UI elements (like health bars) without per-frame allocations.
class WorldUISystem {
  final ComponentCaste<Position> positionCaste;
  final ComponentCaste<WorldUI> worldUiCaste;
  final ComponentCaste<ComplexUI> complexUiCaste;

  WorldUISystem({
    required this.positionCaste,
    required this.worldUiCaste,
    required this.complexUiCaste,
  });

  /// Updates all WorldUI components to translate their world positions to
  /// screen space relative to the given active [cameraViewport].
  void update(Viewport? cameraViewport) {
    if (cameraViewport == null) return;

    final double camX = cameraViewport.x;
    final double camY = cameraViewport.y;
    final double camZoom = cameraViewport.zoom;

    for (var i = 0; i < worldUiCaste.length; i++) {
      final entity = worldUiCaste.elementAt(i);
      final worldUi = worldUiCaste.getComponentAt(i);
      if (worldUi == null) continue;

      final position = positionCaste.get(entity);
      if (position == null) continue;

      final uiEntityId = worldUi.targetUiEntityId.toInt();
      final complexUi = complexUiCaste.get(uiEntityId);
      if (complexUi == null) continue;

      // Calculate screen space position
      // (World Position - Camera Position) * Camera Zoom + Offset
      final double screenX = (position.x - camX) * camZoom + worldUi.offsetX;
      final double screenY = (position.y - camY) * camZoom + worldUi.offsetY;

      // Only update if the coordinate actually changed
      if (complexUi.x != screenX || complexUi.y != screenY) {
        complexUi.x = screenX;
        complexUi.y = screenY;
      }
    }
  }
}
