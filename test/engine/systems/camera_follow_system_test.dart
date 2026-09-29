import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/components/camera_follow.dart';
import 'package:sting/engine/systems/camera_follow_system.dart';

void main() {
  group('CameraFollowSystem', () {
    late ComponentStorage<Position> positionCaste;
    late ComponentStorage<Viewport> viewportCaste;
    late ComponentStorage<CameraFollow> cameraFollowCaste;
    late CameraFollowSystem system;

    const int targetEntityId = 1;
    const int cameraEntityId = 2;
    const int noPositionTargetEntityId = 3;
    const int cameraNoPositionEntityId = 4;

    setUp(() {
      positionCaste = ComponentStorage<Position>(10);
      viewportCaste = ComponentStorage<Viewport>(10);
      cameraFollowCaste = ComponentStorage<CameraFollow>(10);

      system = CameraFollowSystem(
        positionCaste: positionCaste,
        viewportCaste: viewportCaste,
        cameraFollowCaste: cameraFollowCaste,
      );
      system.updateScreenSize(800.0, 600.0);
    });

    test('ignores camera if target entity has no position', () {
      final viewport = Viewport.create(0.0, 0.0, 1.0);
      final cameraFollow =
          CameraFollow.create(targetEntity: noPositionTargetEntityId);

      viewportCaste.add(cameraNoPositionEntityId, viewport);
      cameraFollowCaste.add(cameraNoPositionEntityId, cameraFollow);

      system.update();

      expect(viewport.x, 0.0);
      expect(viewport.y, 0.0);
    });

    test('camera stays still when target is inside deadzone', () {
      final position = Position.create(400.0, 300.0); // Center of screen
      positionCaste.add(targetEntityId, position);

      final viewport =
          Viewport.create(0.0, 0.0, 1.0); // Viewport center is 400, 300
      viewportCaste.add(cameraEntityId, viewport);

      final cameraFollow = CameraFollow.create(
        targetEntity: targetEntityId,
        deadzoneWidth: 100.0, // Deadzone center is 400. Left: 350, Right: 450
        deadzoneHeight: 100.0, // Deadzone center is 300. Top: 250, Bottom: 350
        lerpFactor: 1.0,
      );
      cameraFollowCaste.add(cameraEntityId, cameraFollow);

      // Move target slightly, but still within deadzone
      position.x = 420.0;
      position.y = 320.0;
      system.update();

      // Camera should not move
      expect(viewport.x, 0.0);
      expect(viewport.y, 0.0);
    });

    test('camera moves when target exits deadzone (lerp 1.0)', () {
      final position = Position.create(400.0, 300.0);
      positionCaste.add(targetEntityId, position);

      final viewport =
          Viewport.create(0.0, 0.0, 1.0); // Viewport center is 400, 300
      viewportCaste.add(cameraEntityId, viewport);

      final cameraFollow = CameraFollow.create(
        targetEntity: targetEntityId,
        deadzoneWidth: 100.0, // deadzone left is 350, right is 450
        deadzoneHeight: 100.0, // deadzone top is 250, bottom is 350
        lerpFactor: 1.0,
      );
      cameraFollowCaste.add(cameraEntityId, cameraFollow);

      // Move target significantly outside deadzone
      position.x =
          500.0; // Over right deadzone bound (450) by 50. Desired center X is 450.
      position.y =
          150.0; // Under top deadzone bound (250) by 100. Desired center Y is 200.

      system.update();

      // Desired center X: 500 - 50 = 450. Viewport X: 450 - 400 = 50.
      expect(viewport.x, 50.0);
      // Desired center Y: 150 + 50 = 200. Viewport Y: 200 - 300 = -100.
      expect(viewport.y, -100.0);
    });

    test('camera lerps correctly towards desired center', () {
      final position = Position.create(500.0, 150.0);
      positionCaste.add(targetEntityId, position);

      final viewport = Viewport.create(0.0, 0.0, 1.0); // center is 400, 300
      viewportCaste.add(cameraEntityId, viewport);

      final cameraFollow = CameraFollow.create(
        targetEntity: targetEntityId,
        deadzoneWidth: 100.0,
        deadzoneHeight: 100.0,
        lerpFactor: 0.5,
      );
      cameraFollowCaste.add(cameraEntityId, cameraFollow);

      system.update();

      // Target X=500, deadzoneRight=450. desiredCenter X = 500 - 50 = 450. Diff = 50. 50 * 0.5 = 25. New center X = 425. New VP X = 425 - 400 = 25
      expect(viewport.x, 25.0);
      // Target Y=150, deadzoneTop=250. desiredCenter Y = 150 + 50 = 200. Diff = -100. -100 * 0.5 = -50. New center Y = 250. New VP Y = 250 - 300 = -50
      expect(viewport.y, -50.0);
    });

    test('camera clamps to minX, minY, maxX, maxY', () {
      final position = Position.create(10000.0, -10000.0); // Far away
      positionCaste.add(targetEntityId, position);

      final viewport = Viewport.create(0.0, 0.0, 1.0);
      viewportCaste.add(cameraEntityId, viewport);

      final cameraFollow = CameraFollow.create(
        targetEntity: targetEntityId,
        deadzoneWidth: 0.0,
        deadzoneHeight: 0.0,
        lerpFactor: 1.0,
        minX: -100.0,
        minY: -100.0,
        maxX: 1000.0,
        maxY: 1000.0,
      );
      cameraFollowCaste.add(cameraEntityId, cameraFollow);

      system.update();

      // Camera wants to go to X = 10000 - 400 = 9600. Clamped to 1000.0.
      expect(viewport.x, 1000.0);
      // Camera wants to go to Y = -10000 - 300 = -10300. Clamped to -100.0.
      expect(viewport.y, -100.0);

      // Change target to test minX and maxY
      position.x = -10000.0;
      position.y = 10000.0;
      system.update();

      // Camera wants to go to X = -10000 - 400 = -10400. Clamped to -100.0.
      expect(viewport.x, -100.0);
      // Camera wants to go to Y = 10000 - 300 = 9700. Clamped to 1000.0.
      expect(viewport.y, 1000.0);
    });

    test('camera handles negative bounds clamping correctly', () {
      final position = Position.create(0.0, 0.0);
      positionCaste.add(targetEntityId, position);

      final viewport = Viewport.create(0.0, 0.0, 1.0);
      viewportCaste.add(cameraEntityId, viewport);

      // Let\'s say the camera is confined to a box from -50 to -10
      final cameraFollow = CameraFollow.create(
        targetEntity: targetEntityId,
        lerpFactor: 1.0,
        minX: -50.0,
        maxX: -10.0,
        minY: -50.0,
        maxY: -10.0,
      );
      cameraFollowCaste.add(cameraEntityId, cameraFollow);

      system.update();
      // Desired X = 0 - 400 = -400. Min X is -50, so clamped to -50
      expect(viewport.x, -50.0);

      // Let's test the upper bound for negatives
      position.x = 1000.0;
      system.update();
      // Desired X = 1000 - 400 = 600. Max X is -10, so clamped to -10
      expect(viewport.x, -10.0);
    });

    test('camera takes zoom into account for bounds and centering', () {
      final position = Position.create(800.0, 600.0);
      positionCaste.add(targetEntityId, position);

      // Viewport zoomed in 2x, so viewWidth = 400, viewHeight = 300
      final viewport = Viewport.create(0.0, 0.0, 2.0);
      viewportCaste.add(cameraEntityId, viewport);

      final cameraFollow = CameraFollow.create(
        targetEntity: targetEntityId,
        lerpFactor: 1.0,
        deadzoneWidth: 0.0,
        deadzoneHeight: 0.0,
      );
      cameraFollowCaste.add(cameraEntityId, cameraFollow);

      system.update();

      // Target X = 800. viewWidth/2 = 200. Desired Viewport X = 800 - 200 = 600
      expect(viewport.x, 600.0);
      // Target Y = 600. viewHeight/2 = 150. Desired Viewport Y = 600 - 150 = 450
      expect(viewport.y, 450.0);
    });

    test('updates field values on CameraFollow', () {
      final cameraFollow = CameraFollow.create(targetEntity: 5);
      expect(cameraFollow.targetEntity, 5);

      cameraFollow.targetEntity = 10;
      expect(cameraFollow.targetEntity, 10);

      cameraFollow.deadzoneWidth = 50.0;
      expect(cameraFollow.deadzoneWidth, 50.0);

      cameraFollow.deadzoneHeight = 60.0;
      expect(cameraFollow.deadzoneHeight, 60.0);

      cameraFollow.lerpFactor = 0.8;
      // Close to to avoid float32 precision errors
      expect(cameraFollow.lerpFactor, closeTo(0.8, 0.0001));

      cameraFollow.minX = -10.0;
      expect(cameraFollow.minX, -10.0);

      cameraFollow.minY = -20.0;
      expect(cameraFollow.minY, -20.0);

      cameraFollow.maxX = 10.0;
      expect(cameraFollow.maxX, 10.0);

      cameraFollow.maxY = 20.0;
      expect(cameraFollow.maxY, 20.0);
    });
  });
}
