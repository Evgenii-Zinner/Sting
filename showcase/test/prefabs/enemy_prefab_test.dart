import 'package:flutter_test/flutter_test.dart';

import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/bounding_box.dart';
import '../../lib/components/enemy_ai.dart';
import '../../lib/prefabs/enemy_prefab.dart';

void main() {
  group('Enemy Prefab MVP Tests', () {
    late Scene scene;

    setUp(() {
      scene = Scene();
      scene.registerCaste<Position>('Position', ComponentCaste<Position>(Swarm.maxEntities));
      scene.registerCaste<Velocity>('Velocity', ComponentCaste<Velocity>(Swarm.maxEntities));
      scene.registerCaste<Sprite>('Sprite', ComponentCaste<Sprite>(Swarm.maxEntities));
      scene.registerCaste<BoundingBox>('BoundingBox', ComponentCaste<BoundingBox>(Swarm.maxEntities));
      scene.registerCaste<EnemyAI>('EnemyAI', ComponentCaste<EnemyAI>(Swarm.maxEntities));
    });

    test('spawnEnemy creates entity with correct components', () {
      final targetId = scene.createEntity();
      final enemyId = spawnEnemy(scene, 100.0, 200.0, targetId);

      expect(enemyId, isNot(-1));

      final pos = scene.getCaste<Position>('Position').get(enemyId);
      expect(pos, isNotNull);
      expect(pos!.x, closeTo(100.0, 0.001));
      expect(pos.y, closeTo(200.0, 0.001));

      final vel = scene.getCaste<Velocity>('Velocity').get(enemyId);
      expect(vel, isNotNull);
      expect(vel!.dx, closeTo(0.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));

      final sprite = scene.getCaste<Sprite>('Sprite').get(enemyId);
      expect(sprite, isNotNull);

      final box = scene.getCaste<BoundingBox>('BoundingBox').get(enemyId);
      expect(box, isNotNull);
      expect(box!.width, 24.0);
      expect(box.height, 24.0);

      final ai = scene.getCaste<EnemyAI>('EnemyAI').get(enemyId);
      expect(ai, isNotNull);
      expect(ai!.targetId, targetId);
    });
  });
}
