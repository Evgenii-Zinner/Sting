import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/parallax.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/systems/parallax_system.dart';

void main() {
  group('ParallaxSystem', () {
    late ComponentCaste<Position> positionCaste;
    late ComponentCaste<Parallax> parallaxCaste;
    late ComponentCaste<Viewport> viewportCaste;
    late ParallaxSystem system;

    setUp(() {
      positionCaste = ComponentCaste<Position>(10);
      parallaxCaste = ComponentCaste<Parallax>(10);
      viewportCaste = ComponentCaste<Viewport>(10);

      system = ParallaxSystem(
        positionCaste: positionCaste,
        parallaxCaste: parallaxCaste,
        viewportCaste: viewportCaste,
      );
    });

    test('does nothing if no active camera or viewport', () {
      final entity = 1;
      positionCaste.add(entity, Position.create(10, 20));
      parallaxCaste.add(entity, Parallax.create(0.5, 0.5, 10, 20));

      system.activeCameraEntity = -1;
      system.update();

      final pos = positionCaste.get(entity)!;
      expect(pos.x, 10.0);
      expect(pos.y, 20.0);
    });

    test('updates position based on camera viewport and scroll factors', () {
      final cameraEntity = 0;
      viewportCaste.add(cameraEntity, Viewport.create(100.0, 50.0, 1.0));
      system.activeCameraEntity = cameraEntity;

      final entity1 =
          1; // Factor 1.0 (moves exactly with camera visually, so Position = BasePosition)
      positionCaste.add(entity1, Position.create(0, 0));
      parallaxCaste.add(entity1, Parallax.create(1.0, 1.0, 10.0, 20.0));

      final entity2 =
          2; // Factor 0.0 (static relative to screen, so Position moves opposite to camera translation)
      positionCaste.add(entity2, Position.create(0, 0));
      parallaxCaste.add(entity2, Parallax.create(0.0, 0.0, 10.0, 20.0));

      final entity3 = 3; // Factor 0.5 (moves halfway)
      positionCaste.add(entity3, Position.create(0, 0));
      parallaxCaste.add(entity3, Parallax.create(0.5, 0.5, 10.0, 20.0));

      system.update();

      final pos1 = positionCaste.get(entity1)!;
      expect(pos1.x, closeTo(10.0, 0.001));
      expect(pos1.y, closeTo(20.0, 0.001));

      final pos2 = positionCaste.get(entity2)!;
      expect(pos2.x, closeTo(110.0, 0.001)); // 10.0 + 100.0 * 1.0
      expect(pos2.y, closeTo(70.0, 0.001)); // 20.0 + 50.0 * 1.0

      final pos3 = positionCaste.get(entity3)!;
      expect(pos3.x, closeTo(60.0, 0.001)); // 10.0 + 100.0 * 0.5
      expect(pos3.y, closeTo(45.0, 0.001)); // 20.0 + 50.0 * 0.5
    });
  });
}
