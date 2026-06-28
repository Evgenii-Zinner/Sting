import '../ecs/component_caste.dart';
import '../components/position.dart';
import '../components/viewport.dart';

class CameraSystem {
  final ComponentCaste<Position> positionCaste;
  final ComponentCaste<Viewport> viewportCaste;

  CameraSystem({
    required this.positionCaste,
    required this.viewportCaste,
  });

  /// Updates the camera entity's Viewport based on the target entity's Position.
  void update(int cameraEntity, int targetEntity) {
    final targetPosition = positionCaste.get(targetEntity);
    final cameraViewport = viewportCaste.get(cameraEntity);

    if (targetPosition == null || cameraViewport == null) {
      return;
    }

    cameraViewport.x = targetPosition.x;
    cameraViewport.y = targetPosition.y;
  }
}
