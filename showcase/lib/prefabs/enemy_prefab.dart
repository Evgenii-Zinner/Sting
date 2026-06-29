import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/bounding_box.dart';
import '../components/enemy_ai.dart';

/// Spawns an enemy entity and attaches necessary components for movement and rendering.
int spawnEnemy(Scene scene, double startX, double startY, int targetId) {
  final enemyEntity = scene.createEntity();

  if (enemyEntity != -1) {
    scene.getCaste<Position>('Position').add(enemyEntity, Position.create(startX, startY));
    scene.getCaste<Velocity>('Velocity').add(enemyEntity, Velocity.create(0.0, 0.0));
    scene.getCaste<Sprite>('Sprite').add(enemyEntity, Sprite.create());
    scene.getCaste<BoundingBox>('BoundingBox').add(enemyEntity, BoundingBox.create(24.0, 24.0));
    scene.getCaste<EnemyAI>('EnemyAI').add(enemyEntity, EnemyAI.create(targetId));
  }

  return enemyEntity;
}
