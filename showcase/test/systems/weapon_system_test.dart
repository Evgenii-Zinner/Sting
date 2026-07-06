import "../../lib/components/health.dart";
import "../../lib/components/damage.dart";
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';
import 'package:sting/engine/systems/spatial_hash_system.dart';
import 'package:sting/engine/ecs/query.dart';

import '../../../showcase/lib/components/weapon.dart';
import '../../../showcase/lib/components/enemy_ai.dart';
import '../../../showcase/lib/systems/weapon_system.dart';
import '../../../showcase/lib/prefabs/enemy_prefab.dart';

void main() {
  group('WeaponSystem', () {
    late Scene scene;
    late SpatialHashGrid grid;
    late SpatialHashSystem hashSystem;
    late WeaponSystem weaponSystem;

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
      scene.registerCaste<Weapon>(
          'Weapon', ComponentCaste<Weapon>(Swarm.maxEntities));
      scene.registerCaste<EnemyAI>(
          'EnemyAI', ComponentCaste<EnemyAI>(Swarm.maxEntities));
      scene.registerCaste<Health>("Health", ComponentCaste<Health>(100));
      scene.registerCaste<Damage>("Damage", ComponentCaste<Damage>(100));

      grid = SpatialHashGrid(64.0, 100);
      hashSystem = SpatialHashSystem(grid);
      weaponSystem = WeaponSystem(scene, grid);
    });

    test('reduces cooldown based on dt', () {
      final entity = scene.createEntity();
      final weapon = Weapon.create(1.0, 100.0, 200.0);
      weapon.currentCooldown = 1.0;
      scene.getCaste<Weapon>('Weapon').add(entity, weapon);
      scene
          .getCaste<Position>('Position')
          .add(entity, Position.create(0.0, 0.0));

      weaponSystem.update(0.5);

      expect(weapon.currentCooldown, closeTo(0.5, 0.001));
    });

    test('does not fire when on cooldown', () {
      final player = scene.createEntity();
      final weapon = Weapon.create(1.0, 100.0, 200.0);
      weapon.currentCooldown = 0.5;
      scene.getCaste<Weapon>('Weapon').add(player, weapon);
      scene
          .getCaste<Position>('Position')
          .add(player, Position.create(0.0, 0.0));

      // Enemy in range
      spawnEnemy(scene, 50.0, 0.0, player);
      hashSystem.update(Query1<Position>(scene.getCaste<Position>('Position')));

      final entitiesBefore = scene.getCaste<Velocity>('Velocity').length;

      weaponSystem.update(0.1);

      // Cooldown reduced but didn't fire
      expect(weapon.currentCooldown, closeTo(0.4, 0.001));

      final entitiesAfter = scene.getCaste<Velocity>('Velocity').length;
      expect(
          entitiesAfter, equals(entitiesBefore)); // No new entity (projectile)
    });

    test('does not fire when no enemy in range', () {
      final player = scene.createEntity();
      final weapon = Weapon.create(1.0, 100.0, 200.0);
      weapon.currentCooldown = 0.0;
      scene.getCaste<Weapon>('Weapon').add(player, weapon);
      scene
          .getCaste<Position>('Position')
          .add(player, Position.create(0.0, 0.0));

      // Enemy out of range (range is 200)
      spawnEnemy(scene, 300.0, 0.0, player);
      hashSystem.update(Query1<Position>(scene.getCaste<Position>('Position')));

      final entitiesBefore = scene.getCaste<Velocity>('Velocity').length;

      weaponSystem.update(0.1);

      // Didn't fire
      expect(weapon.currentCooldown, closeTo(-0.1, 0.001));

      final entitiesAfter = scene.getCaste<Velocity>('Velocity').length;
      expect(entitiesAfter, equals(entitiesBefore)); // No new entity
    });

    test('fires at closest enemy when cooldown is ready', () {
      final player = scene.createEntity();
      final weapon = Weapon.create(1.0, 100.0, 200.0);
      weapon.currentCooldown = 0.0;
      scene.getCaste<Weapon>('Weapon').add(player, weapon);
      scene
          .getCaste<Position>('Position')
          .add(player, Position.create(0.0, 0.0));

      // Enemies in range
      spawnEnemy(scene, 100.0, 0.0, player); // Distance 100
      spawnEnemy(scene, 0.0, 50.0, player); // Distance 50 (Closest)
      spawnEnemy(scene, -150.0, 0.0, player); // Distance 150

      hashSystem.update(Query1<Position>(scene.getCaste<Position>('Position')));

      final entitiesBefore = scene.getCaste<Velocity>('Velocity').length;

      weaponSystem.update(0.1);

      // Fired
      expect(weapon.currentCooldown, closeTo(1.0, 0.001));

      final entitiesAfter = scene.getCaste<Velocity>('Velocity').length;
      expect(entitiesAfter, equals(entitiesBefore + 1)); // 1 new entity

      // Find the new projectile (it's the last entity added with Velocity)
      final velCaste = scene.getCaste<Velocity>('Velocity');
      final newEntityId = velCaste.elementAt(velCaste.length - 1);
      final projVel = velCaste.get(newEntityId)!;

      // Enemy was at (0, 50), so direction is (0, 1). Speed is 100.
      expect(projVel.dx, closeTo(0.0, 0.001));
      expect(projVel.dy, closeTo(100.0, 0.001));
    });
  });
}
