import '../ecs/component_caste.dart';
import '../ecs/query.dart';
import '../components/position.dart';
import '../components/viewport.dart';
import '../components/camera_follow.dart';

class CameraFollowSystem {
  final ComponentCaste<Position> positionCaste;
  final ComponentCaste<Viewport> viewportCaste;
  final ComponentCaste<CameraFollow> cameraFollowCaste;
  late final Query2<Viewport, CameraFollow> _cameraQuery;

  double screenWidth = 800.0;
  double screenHeight = 600.0;

  CameraFollowSystem({
    required this.positionCaste,
    required this.viewportCaste,
    required this.cameraFollowCaste,
  }) {
    _cameraQuery = Query2(viewportCaste, cameraFollowCaste);
  }

  void updateScreenSize(double width, double height) {
    screenWidth = width;
    screenHeight = height;
  }

  void update() {
    _cameraQuery.forEach((entityId, viewport, cameraFollow) {
      final targetEntity = cameraFollow.targetEntity;
      final targetPosition = positionCaste.get(targetEntity);

      if (targetPosition == null) {
        return; // Target doesn't have a position
      }

      // Viewport dimensions in world space
      final viewWidth = screenWidth / viewport.zoom;
      final viewHeight = screenHeight / viewport.zoom;

      // Current camera center in world space
      final currentCenterX = viewport.x + viewWidth / 2.0;
      final currentCenterY = viewport.y + viewHeight / 2.0;

      // Target position
      final targetX = targetPosition.x;
      final targetY = targetPosition.y;

      // Calculate the boundaries of the deadzone based on the current camera center
      final deadzoneW = cameraFollow.deadzoneWidth;
      final deadzoneH = cameraFollow.deadzoneHeight;
      final deadzoneLeft = currentCenterX - deadzoneW / 2.0;
      final deadzoneRight = currentCenterX + deadzoneW / 2.0;
      final deadzoneTop = currentCenterY - deadzoneH / 2.0;
      final deadzoneBottom = currentCenterY + deadzoneH / 2.0;

      double desiredCenterX = currentCenterX;
      double desiredCenterY = currentCenterY;

      // If target moves outside the deadzone, shift the desired center
      if (targetX < deadzoneLeft) {
        desiredCenterX = targetX + deadzoneW / 2.0;
      } else if (targetX > deadzoneRight) {
        desiredCenterX = targetX - deadzoneW / 2.0;
      }

      if (targetY < deadzoneTop) {
        desiredCenterY = targetY + deadzoneH / 2.0;
      } else if (targetY > deadzoneBottom) {
        desiredCenterY = targetY - deadzoneH / 2.0;
      }

      // Lerp the center
      final lerp = cameraFollow.lerpFactor;
      final newCenterX = currentCenterX + (desiredCenterX - currentCenterX) * lerp;
      final newCenterY = currentCenterY + (desiredCenterY - currentCenterY) * lerp;

      // Convert back to top-left x/y for the viewport
      double newViewportX = newCenterX - viewWidth / 2.0;
      double newViewportY = newCenterY - viewHeight / 2.0;

      // Clamp to world bounds
      final minX = cameraFollow.minX;
      final minY = cameraFollow.minY;
      final maxX = cameraFollow.maxX;
      final maxY = cameraFollow.maxY;

      if (!minX.isNaN && newViewportX < minX) {
        newViewportX = minX;
      }
      if (!maxX.isNaN && newViewportX > maxX) {
        newViewportX = maxX;
      }
      if (!minY.isNaN && newViewportY < minY) {
        newViewportY = minY;
      }
      if (!maxY.isNaN && newViewportY > maxY) {
        newViewportY = maxY;
      }

      // Set new viewport position
      viewport.x = newViewportX;
      viewport.y = newViewportY;
    });
  }
}
