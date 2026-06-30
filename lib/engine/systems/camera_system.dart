import '../ecs/component_caste.dart';
import '../components/position.dart';
import '../components/viewport.dart';

class CameraSystem {
  final ComponentCaste<Position> positionCaste;
  final ComponentCaste<Viewport> viewportCaste;

  double screenWidth = 800.0;
  double screenHeight = 600.0;

  CameraSystem({
    required this.positionCaste,
    required this.viewportCaste,
  });

  void updateScreenSize(double width, double height) {
    screenWidth = width;
    screenHeight = height;
  }

  /// Updates the camera entity's Viewport based on the target entity's Position.
  void update(int cameraEntity, int targetEntity) {
    final targetPosition = positionCaste.get(targetEntity);
    final cameraViewport = viewportCaste.get(cameraEntity);

    if (targetPosition == null || cameraViewport == null) {
      return;
    }

    cameraViewport.x = targetPosition.x - (screenWidth / 2.0) / cameraViewport.zoom;
    cameraViewport.y = targetPosition.y - (screenHeight / 2.0) / cameraViewport.zoom;
  }
}
