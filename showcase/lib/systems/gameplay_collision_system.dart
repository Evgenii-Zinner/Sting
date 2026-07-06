import 'dart:math';

import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/bounding_box.dart';

import '../components/damage.dart';
import '../components/health.dart';
import '../components/exp_gem.dart';
import '../components/exp_magnet.dart';
import '../components/player_stats.dart';
import '../components/enemy_ai.dart';

/// A system that handles gameplay specific collisions and logic
/// such as projectiles hitting enemies, enemies hitting player,
/// player collecting gems, and magnets attracting gems.
class GameplayCollisionSystem {
  final Scene _scene;
  final SpatialHashGrid _grid;

  // Pre-allocated collections to avoid per-frame GC allocations
  // Calling .clear() keeps the underlying capacity without reallocating
  final List<int> _toDestroy = [];

  final List<double> _spawnGemX = [];
  final List<double> _spawnGemY = [];
  final List<int> _spawnGemVal = [];

  GameplayCollisionSystem(this._scene, this._grid);

  void update(int playerEntityId) {
    _toDestroy.clear();
    _spawnGemX.clear();
    _spawnGemY.clear();
    _spawnGemVal.clear();

    final positionCaste = _scene.getCaste<Position>('Position');
    final velocityCaste = _scene.getCaste<Velocity>('Velocity');
    final boundingBoxCaste = _scene.getCaste<BoundingBox>('BoundingBox');

    final healthCaste = _scene.getCaste<Health>('Health');
    final damageCaste = _scene.getCaste<Damage>('Damage');
    final expGemCaste = _scene.getCaste<ExpGem>('ExpGem');
    final expMagnetCaste = _scene.getCaste<ExpMagnet>('ExpMagnet');
    final playerStatsCaste = _scene.getCaste<PlayerStats>('PlayerStats');
    final enemyAICaste = _scene.getCaste<EnemyAI>('EnemyAI');

    // 1. Process Projectiles
    // A projectile is an entity with Damage but NO EnemyAI (so it's not an enemy dealing damage via touch).
    // Actually, enemies might have Damage. Let's say projectiles have Damage and Velocity but NO EnemyAI, NO Health.
    // Let's iterate all entities with Damage.
    for (int i = 0; i < damageCaste.length; i++) {
      final dmgEntity = damageCaste.elementAt(i);

      // If it's an enemy (has EnemyAI), skip here. We handle enemies hitting player below.
      if (enemyAICaste.get(dmgEntity) != null) continue;

      final dmgPos = positionCaste.get(dmgEntity);
      final dmgBox = boundingBoxCaste.get(dmgEntity);
      final dmgComp = damageCaste.get(dmgEntity);

      if (dmgPos == null || dmgBox == null || dmgComp == null) continue;
      if (_toDestroy.contains(dmgEntity)) continue;

      bool projectileDestroyed = false;

      // Query around projectile
      _grid.queryAABB(dmgPos.x, dmgPos.y, dmgBox.width, dmgBox.height,
          (foundEntity) {
        if (projectileDestroyed) return false;

        // Target must be an enemy and have Health
        if (enemyAICaste.get(foundEntity) != null) {
          final targetPos = positionCaste.get(foundEntity);
          final targetBox = boundingBoxCaste.get(foundEntity);
          final targetHealth = healthCaste.get(foundEntity);

          if (targetPos != null && targetBox != null && targetHealth != null) {
            // Check narrow-phase AABB overlap
            if (_checkAABB(dmgPos, dmgBox, targetPos, targetBox)) {
              // Apply damage
              targetHealth.current -= dmgComp.amount;

              // Destroy projectile
              if (!_toDestroy.contains(dmgEntity)) {
                _toDestroy.add(dmgEntity);
              }
              projectileDestroyed = true;

              // Check if enemy died
              if (targetHealth.current <= 0) {
                if (!_toDestroy.contains(foundEntity)) {
                  _toDestroy.add(foundEntity);

                  _spawnGemX.add(targetPos.x);
                  _spawnGemY.add(targetPos.y);
                  _spawnGemVal.add(10);

                  // Add score
                  final stats = playerStatsCaste.get(playerEntityId);
                  if (stats != null) {
                    stats.score += 100;
                  }
                }
              }
              return false; // Stop querying for this projectile
            }
          }
        }
        return true; // Continue querying
      });
    }

    // 2. Process Enemies hitting Player
    final playerPos = positionCaste.get(playerEntityId);
    final playerBox = boundingBoxCaste.get(playerEntityId);
    final playerHealth = healthCaste.get(playerEntityId);

    if (playerPos != null && playerBox != null && playerHealth != null) {
      _grid.queryAABB(
          playerPos.x, playerPos.y, playerBox.width, playerBox.height,
          (foundEntity) {
        // If found entity is an enemy with damage
        if (enemyAICaste.get(foundEntity) != null) {
          final enemyDmg = damageCaste.get(foundEntity);
          final enemyPos = positionCaste.get(foundEntity);
          final enemyBox = boundingBoxCaste.get(foundEntity);

          if (enemyDmg != null && enemyPos != null && enemyBox != null) {
            if (_checkAABB(playerPos, playerBox, enemyPos, enemyBox)) {
              // Player takes damage
              // We should probably have invincibility frames, but for this MVP, let's just subtract
              // To avoid instantly dying in 1 frame, we could subtract a small amount or add a timer.
              // Let's just do it directly.
              playerHealth.current -= enemyDmg.amount;
              if (playerHealth.current < 0) playerHealth.current = 0;
            }
          }
        }
        return true;
      });
    }

    // 3. Process Player Magnet and Gems
    final magnet = expMagnetCaste.get(playerEntityId);
    if (magnet != null && playerPos != null && playerBox != null) {
      // Center of player
      final px = playerPos.x + playerBox.width / 2;
      final py = playerPos.y + playerBox.height / 2;
      final radius = magnet.radius;

      // Query broad phase for magnet radius
      _grid.queryAABB(px - radius, py - radius, radius * 2, radius * 2,
          (foundEntity) {
        final gem = expGemCaste.get(foundEntity);
        if (gem != null) {
          final gemPos = positionCaste.get(foundEntity);
          final gemBox = boundingBoxCaste.get(foundEntity);

          if (gemPos != null && gemBox != null) {
            // Check if inside magnet radius
            final gx = gemPos.x + gemBox.width / 2;
            final gy = gemPos.y + gemBox.height / 2;

            final dx = gx - px;
            final dy = gy - py;
            final distSq = dx * dx + dy * dy;

            if (distSq <= radius * radius) {
              // Inside magnet. Set gem velocity towards player
              final gemVel = velocityCaste.get(foundEntity);
              if (gemVel != null) {
                final dist = sqrt(distSq);
                if (dist > 0.0) {
                  const double pullSpeed = 400.0;
                  gemVel.dx = (-dx / dist) * pullSpeed;
                  gemVel.dy = (-dy / dist) * pullSpeed;
                }
              }

              // Check narrow phase for actual collection (intersects with player box)
              if (_checkAABB(playerPos, playerBox, gemPos, gemBox)) {
                // Collect gem
                final stats = playerStatsCaste.get(playerEntityId);
                if (stats != null) {
                  stats.xp += gem.xpValue;
                  // Level up check handled in another system or here
                  if (stats.xp >= stats.level * 100) {
                    stats.level += 1;
                    // Maybe reset XP or keep accumulating
                  }
                }
                // Destroy gem
                if (!_toDestroy.contains(foundEntity)) {
                  _toDestroy.add(foundEntity);
                }
              }
            }
          }
        }
        return true;
      });
    }

    // Process queued spawns and destroys
    for (int i = 0; i < _spawnGemX.length; i++) {
      _spawnExpGem(_spawnGemX[i], _spawnGemY[i], _spawnGemVal[i]);
    }
    for (int i = 0; i < _toDestroy.length; i++) {
      _scene.destroyEntity(_toDestroy[i]);
    }
  }

  bool _checkAABB(
      Position posA, BoundingBox boxA, Position posB, BoundingBox boxB) {
    return posA.x < posB.x + boxB.width &&
        posA.x + boxA.width > posB.x &&
        posA.y < posB.y + boxB.height &&
        posA.y + boxA.height > posB.y;
  }

  void _spawnExpGem(double x, double y, int value) {
    final gemEntity = _scene.createEntity();
    if (gemEntity != -1) {
      _scene
          .getCaste<Position>('Position')
          .add(gemEntity, Position.create(x, y));
      // Gems need velocity if magnet pulls them
      _scene
          .getCaste<Velocity>('Velocity')
          .add(gemEntity, Velocity.create(0.0, 0.0));
      // Needs a BoundingBox
      _scene
          .getCaste<BoundingBox>('BoundingBox')
          .add(gemEntity, BoundingBox.create(8.0, 8.0));
      _scene.getCaste<ExpGem>('ExpGem').add(gemEntity, ExpGem.create(value));
    }
  }
}
