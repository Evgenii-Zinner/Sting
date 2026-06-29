import "../../lib/components/health.dart";
import "../../lib/components/damage.dart";
import 'package:flutter_test/flutter_test.dart';

import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import '../../lib/components/enemy_ai.dart';
import '../../lib/systems/chase_system.dart';

void main() {
  group('Chase System MVP Tests', () {
    late Scene scene;
    late ChaseSystem chaseSystem;
    late int playerEntity;
    late int enemyEntity;

    setUp(() {
      scene = Scene();
      scene.registerCaste<Position>('Position', ComponentCaste<Position>(Swarm.maxEntities));
      scene.registerCaste<Velocity>('Velocity', ComponentCaste<Velocity>(Swarm.maxEntities));
      scene.registerCaste<EnemyAI>('EnemyAI', ComponentCaste<EnemyAI>(Swarm.maxEntities));
      scene.registerCaste<Health>("Health", ComponentCaste<Health>(100));
      scene.registerCaste<Damage>("Damage", ComponentCaste<Damage>(100));

      chaseSystem = ChaseSystem(scene, speed: 50.0);

      // Create target (player)
      playerEntity = scene.createEntity();
      scene.getCaste<Position>('Position').add(playerEntity, Position.create(100.0, 100.0));

      // Create chaser (enemy)
      enemyEntity = scene.createEntity();
      scene.getCaste<Position>('Position').add(enemyEntity, Position.create(0.0, 100.0));
      scene.getCaste<Velocity>('Velocity').add(enemyEntity, Velocity.create(0.0, 0.0));
      scene.getCaste<EnemyAI>('EnemyAI').add(enemyEntity, EnemyAI.create(playerEntity));
    });

    test('updates velocity to move towards target', () {
      final vel = scene.getCaste<Velocity>('Velocity').get(enemyEntity)!;
      expect(vel.dx, 0.0);
      expect(vel.dy, 0.0);

      chaseSystem.update();

      // Enemy is at (0, 100), Target is at (100, 100).
      // Delta is (100, 0), normalized is (1, 0).
      // Velocity should be speed (50) in X, 0 in Y.
      expect(vel.dx, closeTo(50.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));
    });

    test('sets velocity to zero when very close', () {
      // Move enemy right on top of player
      final pos = scene.getCaste<Position>('Position').get(enemyEntity)!;
      pos.x = 100.0;
      pos.y = 100.0;

      final vel = scene.getCaste<Velocity>('Velocity').get(enemyEntity)!;
      // Pretend it was moving
      vel.dx = 50.0;
      vel.dy = 50.0;

      chaseSystem.update();

      // Should stop moving to prevent jitter/division by zero
      expect(vel.dx, closeTo(0.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));
    });
  });
}
