import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/camera_trauma.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/camera_shake_system.dart';

void main() {
  group('CameraShakeSystem Tests', () {
    late ComponentStorage<CameraTrauma> traumaCaste;
    late ComponentStorage<Viewport> viewportCaste;
    late CameraShakeSystem system;

    setUp(() {
      traumaCaste = ComponentStorage<CameraTrauma>(10);
      viewportCaste = ComponentStorage<Viewport>(10);
      system = CameraShakeSystem(
        cameraTraumaCaste: traumaCaste,
        viewportCaste: viewportCaste,
      );
    });

    test('update applies decay to trauma', () {
      final trauma = CameraTrauma.create(trauma: 1.0, decayRate: 0.5);
      final viewport = Viewport.create();
      traumaCaste.add(1, trauma);
      viewportCaste.add(1, viewport);

      system.updateEntity(1, 1.0); // 1 second dt

      expect(trauma.trauma, closeTo(0.5, 0.0001));
    });

    test('update clamps trauma decay to 0', () {
      final trauma = CameraTrauma.create(trauma: 0.2, decayRate: 0.5);
      final viewport = Viewport.create();
      traumaCaste.add(1, trauma);
      viewportCaste.add(1, viewport);

      system.updateEntity(1, 1.0); // 1 second dt

      expect(trauma.trauma, equals(0.0));
    });

    test('update applies translation based on trauma and shake', () {
      final trauma = CameraTrauma.create(
        trauma: 1.0,
        decayRate: 0.0, // Prevent decay to keep calculation simple
        maxTranslationX: 10.0,
        maxTranslationY: 20.0,
        frequency: 1.0,
      );
      final viewport = Viewport.create(100.0, 100.0, 1.0);
      traumaCaste.add(1, trauma);
      viewportCaste.add(1, viewport);

      system.updateEntity(1, 0.5); // dt > 0 to change time

      // Because pseudo-noise will generate values between -1 and 1,
      // the viewport x and y should change from their initial 100.0.
      expect(viewport.x, isNot(equals(100.0)));
      expect(viewport.y, isNot(equals(100.0)));

      // We can also test bounds
      expect(viewport.x, greaterThanOrEqualTo(90.0));
      expect(viewport.x, lessThanOrEqualTo(110.0));
      expect(viewport.y, greaterThanOrEqualTo(80.0));
      expect(viewport.y, lessThanOrEqualTo(120.0));
    });

    test('update applies rotation based on trauma and shake', () {
      final trauma = CameraTrauma.create(
        trauma: 1.0,
        decayRate: 0.0,
        maxRotation: 0.5, // max rotation
        frequency: 1.0,
      );
      final viewport = Viewport.create(100.0, 100.0, 1.0, 0.0);
      traumaCaste.add(1, trauma);
      viewportCaste.add(1, viewport);

      system.updateEntity(1, 0.5);

      expect(viewport.angle, isNot(equals(0.0)));
      expect(viewport.angle, greaterThanOrEqualTo(-0.5));
      expect(viewport.angle, lessThanOrEqualTo(0.5));
    });

    test('update does not shake if trauma is 0', () {
      final trauma = CameraTrauma.create(
        trauma: 0.0,
        decayRate: 0.5,
        maxTranslationX: 10.0,
        maxTranslationY: 20.0,
        frequency: 1.0,
      );
      final viewport = Viewport.create(100.0, 100.0, 1.0);
      traumaCaste.add(1, trauma);
      viewportCaste.add(1, viewport);

      system.updateEntity(1, 0.5);

      expect(viewport.x, equals(100.0));
      expect(viewport.y, equals(100.0));
    });

    test('update list of entities advances time only once per update call', () {
      final trauma1 = CameraTrauma.create(trauma: 1.0, decayRate: 0.0, maxTranslationX: 10.0);
      final viewport1 = Viewport.create(100.0, 100.0, 1.0);
      traumaCaste.add(1, trauma1);
      viewportCaste.add(1, viewport1);

      final trauma2 = CameraTrauma.create(trauma: 1.0, decayRate: 0.0, maxTranslationX: 10.0);
      final viewport2 = Viewport.create(100.0, 100.0, 1.0);
      traumaCaste.add(2, trauma2);
      viewportCaste.add(2, viewport2);

      system.update([1, 2], 0.5);

      // Because time advanced exactly the same for both, they should have the identical new offset
      expect(viewport1.x, equals(viewport2.x));
    });

    test('addTrauma clamps to 1.0', () {
      final trauma = CameraTrauma.create(trauma: 0.5);

      trauma.addTrauma(0.2);
      expect(trauma.trauma, closeTo(0.7, 0.0001));

      trauma.addTrauma(0.5);
      expect(trauma.trauma, equals(1.0));

      trauma.addTrauma(-0.5);
      expect(trauma.trauma, equals(0.5));
    });
  });
}
