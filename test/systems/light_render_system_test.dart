import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/entity_manager.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/light.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/shadow_caster.dart';
import 'package:sting/engine/systems/light_render_system.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';
import 'dart:ui';

class MockCanvas extends Fake implements Canvas {
  int drawPathCalls = 0;
  int drawRectCalls = 0;

  @override
  void drawPath(Path path, Paint paint) {
    drawPathCalls++;
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    drawRectCalls++;
  }

  @override
  void save() {}

  @override
  void restore() {}

  @override
  void scale(double sx, [double? sy]) {}

  @override
  void translate(double dx, double dy) {}
}

void main() {
  group('LightRenderSystem', () {
    late EntityManager swarm;
    late ComponentStorage<Position> positionCaste;
    late ComponentStorage<Light> lightCaste;
    late ComponentStorage<BoundingBox> boundingBoxCaste;
    late ComponentStorage<ShadowCaster> shadowCasterCaste;
    late LightRenderSystem system;

    setUp(() {
      swarm = EntityManager();
      positionCaste = ComponentStorage<Position>(10);
      lightCaste = ComponentStorage<Light>(10);
      boundingBoxCaste = ComponentStorage<BoundingBox>(10);
      shadowCasterCaste = ComponentStorage<ShadowCaster>(10);

      system = LightRenderSystem(
        positionCaste: positionCaste,
        lightCaste: lightCaste,
        boundingBoxCaste: boundingBoxCaste,
        shadowCasterCaste: shadowCasterCaste,
        rayCount: 4, // low ray count for faster test
        renderAmbient: false,
      );
    });

    test('should render lights correctly', () {
      final lightEntity = swarm.createEntity();
      positionCaste.add(lightEntity, Position.create(100, 100));
      lightCaste.add(lightEntity, Light.create(radius: 50.0));

      final canvas = MockCanvas();
      system.render(canvas, const Size(800, 600));

      // Should draw exactly one path for the light (since renderAmbient is false)
      expect(canvas.drawPathCalls, 1);
      expect(canvas.drawRectCalls, 0);
    });

    test('should compute shadows when shadow casters are present', () {
      final lightEntity = swarm.createEntity();
      positionCaste.add(lightEntity, Position.create(100, 100));
      lightCaste.add(lightEntity, Light.create(radius: 50.0));

      // Shadow caster to the right
      final shadowEntity = swarm.createEntity();
      positionCaste.add(shadowEntity, Position.create(120, 90));
      boundingBoxCaste.add(shadowEntity, BoundingBox.create(20, 20));
      shadowCasterCaste.add(shadowEntity, ShadowCaster.create());

      final canvas = MockCanvas();
      system.render(canvas, const Size(800, 600));

      expect(canvas.drawPathCalls, 1);
    });

    test('should compute shadows with spatial hash grid', () {
      final grid = SpatialHashGrid(50, 200);
      system.spatialHashGrid = grid;

      final lightEntity = swarm.createEntity();
      positionCaste.add(lightEntity, Position.create(100, 100));
      lightCaste.add(lightEntity, Light.create(radius: 50.0));

      // Shadow caster
      final shadowEntity = swarm.createEntity();
      positionCaste.add(shadowEntity, Position.create(120, 90));
      boundingBoxCaste.add(shadowEntity, BoundingBox.create(20, 20));
      shadowCasterCaste.add(shadowEntity, ShadowCaster.create());

      grid.insertPoint(shadowEntity, 120, 90);

      final canvas = MockCanvas();
      system.render(canvas, const Size(800, 600));

      expect(canvas.drawPathCalls, 1);
    });

    test('should draw ambient light', () {
      system.renderAmbient = true;
      final canvas = MockCanvas();
      system.render(canvas, const Size(800, 600));

      expect(canvas.drawRectCalls, 1);
      expect(canvas.drawPathCalls, 0); // No lights
    });

    test('should respect light active flag', () {
      final lightEntity = swarm.createEntity();
      positionCaste.add(lightEntity, Position.create(100, 100));
      lightCaste.add(lightEntity, Light.create(radius: 50.0, active: false));

      final canvas = MockCanvas();
      system.render(canvas, const Size(800, 600));

      expect(canvas.drawPathCalls, 0);
    });
  });
}
