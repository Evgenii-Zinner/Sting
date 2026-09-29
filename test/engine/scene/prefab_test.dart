import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/scene/prefab.dart';

void main() {
  group('Prefab', () {
    late Scene scene;

    setUp(() {
      scene = Scene();
    });

    test('spawnStandardEnemy creates entity with all required components', () {
      // Register required castes
      scene.registerCaste<Position>(
          'Position', ComponentStorage<Position>(100));
      scene.registerCaste<Velocity>(
          'Velocity', ComponentStorage<Velocity>(100));
      scene.registerCaste<BoundingBox>(
          'BoundingBox', ComponentStorage<BoundingBox>(100));
      scene.registerCaste<Sprite>('Sprite', ComponentStorage<Sprite>(100));

      final entity = Prefab.spawnStandardEnemy(
        scene,
        10.0,
        20.0,
        -5.0,
        5.0,
        32.0,
        32.0,
      );

      expect(entity, 0);

      final position = scene.getCaste<Position>('Position').get(entity);
      expect(position, isNotNull);
      expect(position!.x, 10.0);
      expect(position.y, 20.0);

      final velocity = scene.getCaste<Velocity>('Velocity').get(entity);
      expect(velocity, isNotNull);
      expect(velocity!.dx, -5.0);
      expect(velocity.dy, 5.0);

      final bbox = scene.getCaste<BoundingBox>('BoundingBox').get(entity);
      expect(bbox, isNotNull);
      expect(bbox!.width, 32.0);
      expect(bbox.height, 32.0);

      final sprite = scene.getCaste<Sprite>('Sprite').get(entity);
      expect(sprite, isNotNull);
    });

    test('spawnStandardEnemy throws StateError if a required caste is missing',
        () {
      // Register all but Sprite
      scene.registerCaste<Position>(
          'Position', ComponentStorage<Position>(100));
      scene.registerCaste<Velocity>(
          'Velocity', ComponentStorage<Velocity>(100));
      scene.registerCaste<BoundingBox>(
          'BoundingBox', ComponentStorage<BoundingBox>(100));

      expect(
        () => Prefab.spawnStandardEnemy(scene, 0, 0, 0, 0, 10, 10),
        throwsStateError,
      );
    });

    test('spawnStandardEnemy returns -1 if max entities reached', () {
      // Fast forward the EntityManager inside scene to max entities
      scene.registerCaste<Position>(
          'Position', ComponentStorage<Position>(100));
      scene.registerCaste<Velocity>(
          'Velocity', ComponentStorage<Velocity>(100));
      scene.registerCaste<BoundingBox>(
          'BoundingBox', ComponentStorage<BoundingBox>(100));
      scene.registerCaste<Sprite>('Sprite', ComponentStorage<Sprite>(100));

      for (var i = 0; i < 65535; i++) {
        scene.createEntity();
      }

      final entity = Prefab.spawnStandardEnemy(scene, 0, 0, 0, 0, 10, 10);
      expect(entity, -1);
    });
  });
}
