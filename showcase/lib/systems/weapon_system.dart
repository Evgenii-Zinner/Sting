import 'dart:math';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';
import '../components/weapon.dart';
import '../components/enemy_ai.dart';
import '../prefabs/projectile_prefab.dart';

/// A system that handles weapon cooldowns and auto-firing logic.
class WeaponSystem {
  final Scene _scene;
  final SpatialHashGrid _grid;

  WeaponSystem(this._scene, this._grid);

  /// Updates weapon cooldowns and fires projectiles at the nearest enemy in range.
  void update(double dt) {
    final weaponCaste = _scene.getCaste<Weapon>('Weapon');
    final positionCaste = _scene.getCaste<Position>('Position');

    // We need EnemyAI caste to verify if a found entity is actually an enemy
    final enemyAICaste = _scene.getCaste<EnemyAI>('EnemyAI');

    final query = Query2<Weapon, Position>(weaponCaste, positionCaste);

    query.forEach((entity, weapon, position) {
      weapon.currentCooldown -= dt;

      if (weapon.currentCooldown <= 0.0) {
        final range = weapon.range;

        // Find nearest enemy in range
        int nearestEnemy = -1;
        double nearestDistSq = range * range;

        // Define the AABB to search
        final searchX = position.x - range;
        final searchY = position.y - range;
        final searchSize = range * 2;

        _grid.queryAABB(searchX, searchY, searchSize, searchSize,
            (foundEntity) {
          // Check if the entity is an enemy and not ourselves
          if (foundEntity != entity && enemyAICaste.get(foundEntity) != null) {
            final enemyPos = positionCaste.get(foundEntity);
            if (enemyPos != null) {
              final dx = enemyPos.x - position.x;
              final dy = enemyPos.y - position.y;
              final distSq = dx * dx + dy * dy;

              if (distSq < nearestDistSq) {
                nearestDistSq = distSq;
                nearestEnemy = foundEntity;
              }
            }
          }
          return true; // Continue querying
        });

        if (nearestEnemy != -1) {
          // Fire projectile
          final enemyPos = positionCaste.get(nearestEnemy)!;
          final dx = enemyPos.x - position.x;
          final dy = enemyPos.y - position.y;

          // Should not be zero since we found an enemy in range, but guard against it
          final dist = sqrt(dx * dx + dy * dy);
          if (dist > 0.0) {
            final nx = dx / dist;
            final ny = dy / dist;
            final speed = weapon.projectileSpeed;

            spawnProjectile(
                _scene, position.x, position.y, nx * speed, ny * speed);
            weapon.currentCooldown = weapon.fireRate;
          }
        }
      }
    });
  }
}
