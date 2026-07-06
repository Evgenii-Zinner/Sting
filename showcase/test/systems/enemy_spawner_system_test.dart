import "../../lib/components/health.dart";
import "../../lib/components/damage.dart";
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/viewport.dart';
import '../../lib/components/enemy_ai.dart';
import '../../lib/systems/enemy_spawner_system.dart';

void main() {
  group('Enemy Spawner System MVP Tests', () {
    late Scene scene;
    late EnemySpawnerSystem spawnerSystem;
    late int viewportEntity;
    late int playerEntity;

    setUp(() {
      scene = Scene();
      scene.registerCaste<Position>(
          'Position', ComponentCaste<Position>(Swarm.maxEntities));
      scene.registerCaste<Velocity>(
          'Velocity', ComponentCaste<Velocity>(Swarm.maxEntities));
      scene.registerCaste<Sprite>(
          'Sprite', ComponentCaste<Sprite>(Swarm.maxEntities));
      scene.registerCaste<BoundingBox>(
          'BoundingBox', ComponentCaste<BoundingBox>(Swarm.maxEntities));
      scene.registerCaste<EnemyAI>(
          'EnemyAI', ComponentCaste<EnemyAI>(Swarm.maxEntities));
      scene.registerCaste<Health>("Health", ComponentCaste<Health>(100));
      scene.registerCaste<Damage>("Damage", ComponentCaste<Damage>(100));
      scene.registerCaste<Viewport>('Viewport', ComponentCaste<Viewport>(1));

      viewportEntity = scene.createEntity();
      scene.getCaste<Viewport>('Viewport').add(
          viewportEntity,
          Viewport.create()
            ..x = 0.0
            ..y = 0.0);

      playerEntity = scene.createEntity();
      scene
          .getCaste<Position>('Position')
          .add(playerEntity, Position.create(100.0, 100.0));

      spawnerSystem = EnemySpawnerSystem(scene, spawnInterval: 1.0);
      spawnerSystem.setTargetEntity(playerEntity);
      spawnerSystem.updateScreenSize(800.0, 600.0);
    });

    test('spawns enemy when interval is met', () {
      final initialCount = scene.getCaste<EnemyAI>('EnemyAI').length;
      expect(initialCount, 0);

      // Not enough time passed
      spawnerSystem.update(0.5);
      expect(scene.getCaste<EnemyAI>('EnemyAI').length, 0);

      // Enough time passed
      spawnerSystem.update(0.6); // Total 1.1s > 1.0s interval
      expect(scene.getCaste<EnemyAI>('EnemyAI').length, 1);

      // Ensure spawned entity has correct target ID
      final aiCaste = scene.getCaste<EnemyAI>('EnemyAI');
      final enemyEntity = aiCaste.elementAt(0);
      final ai = aiCaste.get(enemyEntity);
      expect(ai!.targetId, playerEntity);
    });
  });
}
