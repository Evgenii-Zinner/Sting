import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/circle_collider.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/systems/collision_system.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';
import 'package:sting/engine/systems/spatial_hash_system.dart';
import 'package:sting/engine/ecs/query.dart';

void main() {
  group('CollisionSystem', () {
    late SpatialHashGrid grid;
    late SpatialHashSystem hashSystem;
    late ComponentCaste<Position> positions;
    late ComponentCaste<BoundingBox> boxes;
    late ComponentCaste<CircleCollider> circles;
    late CollisionSystem system;

    setUp(() {
      grid = SpatialHashGrid(64.0, 1024);
      hashSystem = SpatialHashSystem(grid);
      positions = ComponentCaste<Position>(Swarm.maxEntities);
      boxes = ComponentCaste<BoundingBox>(Swarm.maxEntities);
      circles = ComponentCaste<CircleCollider>(Swarm.maxEntities);

      system = CollisionSystem(
        grid,
        positions,
        boundingBoxCaste: boxes,
        circleColliderCaste: circles,
      );
    });

    test('checkAABBAABB detects overlap', () {
      positions.add(1, Position.create(10.0, 10.0));
      boxes.add(1, BoundingBox.create(20.0, 20.0));

      positions.add(2, Position.create(20.0, 20.0));
      boxes.add(2, BoundingBox.create(20.0, 20.0));

      // Far away, no overlap
      positions.add(3, Position.create(100.0, 100.0));
      boxes.add(3, BoundingBox.create(20.0, 20.0));

      // Update spatial hash
      hashSystem.update(Query1<Position>(positions));

      final collisions = <(int, int)>[];
      system.checkAABBAABB((a, b) {
        collisions.add((a, b));
      });

      expect(collisions.length, 1);
      // Because we ensure entityA < entityB
      expect(collisions.first, (1, 2));
    });

    test('checkCircleCircle detects overlap', () {
      positions.add(1, Position.create(10.0, 10.0));
      circles.add(1, CircleCollider.create(10.0));

      positions.add(
          2,
          Position.create(
              20.0, 20.0)); // Center distance is ~14.1, radii sum is 20
      circles.add(2, CircleCollider.create(10.0));

      positions.add(3, Position.create(100.0, 100.0));
      circles.add(3, CircleCollider.create(10.0));

      hashSystem.update(Query1<Position>(positions));

      final collisions = <(int, int)>[];
      system.checkCircleCircle((a, b) {
        collisions.add((a, b));
      });

      expect(collisions.length, 1);
      expect(collisions.first, (1, 2));
    });

    test('checkAABBCircle detects overlap', () {
      // Box
      positions.add(1, Position.create(10.0, 10.0));
      boxes.add(1, BoundingBox.create(20.0, 20.0));

      // Circle intersecting box
      positions.add(2, Position.create(35.0, 20.0));
      circles.add(2, CircleCollider.create(10.0));

      // Circle not intersecting
      positions.add(3, Position.create(100.0, 100.0));
      circles.add(3, CircleCollider.create(10.0));

      hashSystem.update(Query1<Position>(positions));

      final collisions = <(int, int)>[];
      system.checkAABBCircle((a, b) {
        collisions.add((a, b));
      });

      expect(collisions.length, 1);
      expect(collisions.first, (1, 2));
    });

    test('systems checks do not allocate', () {
      // Setup many entities
      for (int i = 0; i < 1000; i++) {
        positions.add(i, Position.create(i * 1.5, i * 1.5));
        boxes.add(i, BoundingBox.create(10.0, 10.0));
        circles.add(i, CircleCollider.create(5.0));
      }

      hashSystem.update(Query1<Position>(positions));

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        system.checkAABBAABB((a, b) {});
        system.checkCircleCircle((a, b) {});
        system.checkAABBCircle((a, b) {});
      }
      stopwatch.stop();

      // Ensure reasonable execution time indicating no major GC hits
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    test('gracefully handles missing castes', () {
      final systemMissing = CollisionSystem(grid, positions);

      positions.add(1, Position.create(10.0, 10.0));
      hashSystem.update(Query1<Position>(positions));

      // Should not throw
      systemMissing.checkAABBAABB((a, b) {});
      systemMissing.checkCircleCircle((a, b) {});
      systemMissing.checkAABBCircle((a, b) {});
    });
  });
}
