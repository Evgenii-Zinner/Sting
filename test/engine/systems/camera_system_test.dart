import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/systems/camera_system.dart';

void main() {
  group('CameraSystem', () {
    late Swarm swarm;
    late ComponentCaste<Position> positionCaste;
    late ComponentCaste<Viewport> viewportCaste;
    late CameraSystem system;

    setUp(() {
      swarm = Swarm();
      positionCaste = ComponentCaste<Position>(10);
      viewportCaste = ComponentCaste<Viewport>(10);
      system = CameraSystem(
        positionCaste: positionCaste,
        viewportCaste: viewportCaste,
      );
    });

    test('updates camera viewport precisely to target position', () {
      final cameraEntity = swarm.createEntity();
      final targetEntity = swarm.createEntity();

      final viewport = Viewport.create(0.0, 0.0, 1.0);
      viewportCaste.add(cameraEntity, viewport);

      final position = Position.create(150.5, 300.2);
      positionCaste.add(targetEntity, position);

      system.update(cameraEntity, targetEntity);

      final updatedViewport = viewportCaste.get(cameraEntity);
      expect(updatedViewport, isNotNull);
      expect(updatedViewport!.x, closeTo(150.5, 0.001));
      expect(updatedViewport.y, closeTo(300.2, 0.001));
      expect(updatedViewport.zoom, 1.0); // Should remain unchanged
    });

    test('does nothing if target position is missing', () {
      final cameraEntity = swarm.createEntity();
      final targetEntity = swarm.createEntity();

      final viewport = Viewport.create(10.0, 20.0, 1.0);
      viewportCaste.add(cameraEntity, viewport);

      // Intentionally not adding Position to targetEntity

      system.update(cameraEntity, targetEntity);

      final updatedViewport = viewportCaste.get(cameraEntity);
      expect(updatedViewport, isNotNull);
      expect(updatedViewport!.x, 10.0);
      expect(updatedViewport.y, 20.0);
    });

    test('does nothing if camera viewport is missing', () {
      final cameraEntity = swarm.createEntity();
      final targetEntity = swarm.createEntity();

      // Intentionally not adding Viewport to cameraEntity

      final position = Position.create(150.5, 300.2);
      positionCaste.add(targetEntity, position);

      system.update(cameraEntity, targetEntity);

      // Should run without throwing errors
      expect(() => system.update(cameraEntity, targetEntity), returnsNormally);
    });
  });
}
