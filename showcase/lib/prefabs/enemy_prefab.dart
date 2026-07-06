import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/bounding_box.dart';
import '../components/enemy_ai.dart';
import '../components/health.dart';
import '../components/damage.dart';

/// Spawns an enemy entity and attaches necessary components for movement and rendering.
int spawnEnemy(Scene scene, double startX, double startY, int targetId) {
  final enemyEntity = scene.createEntity();

  if (enemyEntity != -1) {
    scene
        .getCaste<Position>('Position')
        .add(enemyEntity, Position.create(startX, startY));
    scene
        .getCaste<Velocity>('Velocity')
        .add(enemyEntity, Velocity.create(0.0, 0.0));

    final sprite = Sprite.create();
    // Atlas enemy frames start at y = 160
    sprite.rectLeft = 0.0;
    sprite.rectTop = 160.0;
    sprite.rectRight = 32.0;
    sprite.rectBottom = 192.0;
    scene.getCaste<Sprite>('Sprite').add(enemyEntity, sprite);

    scene
        .getCaste<BoundingBox>('BoundingBox')
        .add(enemyEntity, BoundingBox.create(24.0, 24.0));
    scene
        .getCaste<EnemyAI>('EnemyAI')
        .add(enemyEntity, EnemyAI.create(targetId));

    // Add gameplay stats
    scene.getCaste<Health>('Health').add(enemyEntity, Health.create(30));
    scene.getCaste<Damage>('Damage').add(enemyEntity, Damage.create(5));
  }

  return enemyEntity;
}
