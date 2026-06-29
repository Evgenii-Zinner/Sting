import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';
import 'package:sting/engine/systems/spatial_hash_system.dart';
import 'package:sting/engine/ecs/query.dart';

import '../../lib/components/health.dart';
import '../../lib/components/damage.dart';
import '../../lib/components/enemy_ai.dart';
import '../../lib/components/exp_gem.dart';
import '../../lib/components/exp_magnet.dart';
import '../../lib/components/player_stats.dart';
import '../../lib/systems/gameplay_collision_system.dart';

void main() {
  group('GameplayCollisionSystem', () {
    late Scene scene;
    late SpatialHashGrid grid;
    late SpatialHashSystem gridSystem;
    late GameplayCollisionSystem system;
    late int playerEntity;

    setUp(() {
      scene = Scene();
      grid = SpatialHashGrid(64.0, 100);
      gridSystem = SpatialHashSystem(grid);
      system = GameplayCollisionSystem(scene, grid);

      scene.registerCaste<Position>('Position', ComponentCaste<Position>(100));
      scene.registerCaste<Velocity>('Velocity', ComponentCaste<Velocity>(100));
      scene.registerCaste<BoundingBox>('BoundingBox', ComponentCaste<BoundingBox>(100));
      scene.registerCaste<Health>('Health', ComponentCaste<Health>(100));
      scene.registerCaste<Damage>('Damage', ComponentCaste<Damage>(100));
      scene.registerCaste<ExpGem>('ExpGem', ComponentCaste<ExpGem>(100));
      scene.registerCaste<ExpMagnet>('ExpMagnet', ComponentCaste<ExpMagnet>(100));
      scene.registerCaste<PlayerStats>('PlayerStats', ComponentCaste<PlayerStats>(100));
      scene.registerCaste<EnemyAI>('EnemyAI', ComponentCaste<EnemyAI>(100));

      playerEntity = scene.createEntity();
      scene.getCaste<Position>('Position').add(playerEntity, Position.create(100.0, 100.0));
      scene.getCaste<BoundingBox>('BoundingBox').add(playerEntity, BoundingBox.create(20.0, 20.0));
      scene.getCaste<Health>('Health').add(playerEntity, Health.create(100));
      scene.getCaste<ExpMagnet>('ExpMagnet').add(playerEntity, ExpMagnet.create(50.0));
      scene.getCaste<PlayerStats>('PlayerStats').add(playerEntity, PlayerStats.create());
    });

    test('Projectile deals damage to enemy and spawns gem on kill', () {
      final enemy = scene.createEntity();
      scene.getCaste<Position>('Position').add(enemy, Position.create(200.0, 200.0));
      scene.getCaste<BoundingBox>('BoundingBox').add(enemy, BoundingBox.create(20.0, 20.0));
      scene.getCaste<Health>('Health').add(enemy, Health.create(10));
      scene.getCaste<EnemyAI>('EnemyAI').add(enemy, EnemyAI.create(playerEntity));

      final projectile = scene.createEntity();
      scene.getCaste<Position>('Position').add(projectile, Position.create(205.0, 205.0)); // Overlapping
      scene.getCaste<BoundingBox>('BoundingBox').add(projectile, BoundingBox.create(5.0, 5.0));
      scene.getCaste<Damage>('Damage').add(projectile, Damage.create(15)); // Enough to kill

      gridSystem.update(Query1<Position>(scene.getCaste<Position>('Position')));
      system.update(playerEntity);

      // Projectile should be destroyed
      expect(scene.getCaste<Position>('Position').get(projectile), isNull);

      // Enemy should be destroyed
      expect(scene.getCaste<Position>('Position').get(enemy), isNull);

      // A gem should be spawned (find entity with ExpGem)
      final expGemCaste = scene.getCaste<ExpGem>('ExpGem');
      bool gemFound = false;
      for (int i = 0; i < expGemCaste.length; i++) {
        final ent = expGemCaste.elementAt(i);
        if (expGemCaste.get(ent) != null) gemFound = true;
      }
      expect(gemFound, isTrue);

      // Score should increase
      final stats = scene.getCaste<PlayerStats>('PlayerStats').get(playerEntity);
      expect(stats!.score, 100);
    });

    test('Enemy deals damage to player', () {
      final enemy = scene.createEntity();
      scene.getCaste<Position>('Position').add(enemy, Position.create(105.0, 105.0)); // Overlapping player
      scene.getCaste<BoundingBox>('BoundingBox').add(enemy, BoundingBox.create(20.0, 20.0));
      scene.getCaste<Damage>('Damage').add(enemy, Damage.create(15));
      scene.getCaste<EnemyAI>('EnemyAI').add(enemy, EnemyAI.create(playerEntity));

      gridSystem.update(Query1<Position>(scene.getCaste<Position>('Position')));
      system.update(playerEntity);

      final health = scene.getCaste<Health>('Health').get(playerEntity);
      expect(health!.current, 85);
    });

    test('Player magnet attracts gem and player collects it', () {
      final gem = scene.createEntity();
      // Initially outside player box but inside magnet radius (100+10+50 = 160)
      // Magnet radius is 50. Player center is 110,110. Radius 50 means 60 to 160.
      scene.getCaste<Position>('Position').add(gem, Position.create(140.0, 110.0));
      scene.getCaste<Velocity>('Velocity').add(gem, Velocity.create(0.0, 0.0));
      scene.getCaste<BoundingBox>('BoundingBox').add(gem, BoundingBox.create(10.0, 10.0));
      scene.getCaste<ExpGem>('ExpGem').add(gem, ExpGem.create(25));

      gridSystem.update(Query1<Position>(scene.getCaste<Position>('Position')));
      system.update(playerEntity);

      // Should be pulled
      final vel = scene.getCaste<Velocity>('Velocity').get(gem);
      expect(vel!.dx, lessThan(0.0)); // moving left towards player

      // Now move it inside player manually for next tick
      scene.getCaste<Position>('Position').get(gem)!.x = 105.0;

      gridSystem.update(Query1<Position>(scene.getCaste<Position>('Position')));
      system.update(playerEntity);

      // Gem collected
      expect(scene.getCaste<Position>('Position').get(gem), isNull);

      final stats = scene.getCaste<PlayerStats>('PlayerStats').get(playerEntity);
      expect(stats!.xp, 25);
    });
  });
}
