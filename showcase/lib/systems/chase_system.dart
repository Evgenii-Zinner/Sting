import 'dart:math';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import '../components/enemy_ai.dart';

/// A system that makes entities with `EnemyAI` chase their target's `Position`.
class ChaseSystem {
  final Scene scene;
  final double speed;

  ChaseSystem(this.scene, {this.speed = 100.0});

  /// Updates velocities for chasing entities. Operates with zero allocations.
  void update() {
    final aiCaste = scene.getCaste<EnemyAI>('EnemyAI');
    final positionCaste = scene.getCaste<Position>('Position');
    final velocityCaste = scene.getCaste<Velocity>('Velocity');

    final length = aiCaste.length;
    for (var i = 0; i < length; i++) {
      final entity = aiCaste.elementAt(i);
      final ai = aiCaste.getComponentAt(i);
      if (ai == null) continue;

      final targetId = ai.targetId;
      if (targetId == -1) continue;

      final myPos = positionCaste.get(entity);
      final targetPos = positionCaste.get(targetId);
      final myVel = velocityCaste.get(entity);

      if (myPos != null && targetPos != null && myVel != null) {
        final dx = targetPos.x - myPos.x;
        final dy = targetPos.y - myPos.y;

        // Calculate distance (avoid sqrt if possible, but needed for normalization here)
        final distSq = dx * dx + dy * dy;

        if (distSq > 0.1) {
          final dist = sqrt(distSq);
          final nx = dx / dist;
          final ny = dy / dist;

          myVel.dx = nx * speed;
          myVel.dy = ny * speed;
        } else {
          myVel.dx = 0.0;
          myVel.dy = 0.0;
        }
      }
    }
  }
}
