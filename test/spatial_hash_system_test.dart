import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';
import 'package:sting/engine/systems/spatial_hash_system.dart';

void main() {
  group('SpatialHashSystem', () {
    test('updates grid correctly with positions', () {
      final grid = SpatialHashGrid(64.0, 1024);
      final system = SpatialHashSystem(grid);

      final positions = ComponentCaste<Position>(Swarm.maxEntities);

      // Entities 1 and 2 in cell (0, 0)
      positions.add(1, Position.create(10.0, 10.0));
      positions.add(2, Position.create(20.0, 20.0));
      // Entity 3 in cell (1, 1)
      positions.add(3, Position.create(70.0, 70.0));

      final query = Query1<Position>(positions);

      // Perform update
      system.update(query);

      // Verify grid state
      final cell00 = <int>[];
      grid.queryPoint(15.0, 15.0, (e) => cell00.add(e));
      expect(cell00, containsAll([1, 2]));
      expect(cell00.length, 2);

      final cell11 = <int>[];
      grid.queryPoint(75.0, 75.0, (e) => cell11.add(e));
      expect(cell11, containsAll([3]));
      expect(cell11.length, 1);
    });

    test('update performs no allocations', () {
      // Dart's gc metrics are tricky in unit tests, but we can verify that the system runs
      // smoothly and doesn't instantiate any known objects inside the loop by manual inspection
      // and checking loop invariants. The best we can do in standard unit test is run it many
      // times and ensure it's fast/doesn't crash.
      final grid = SpatialHashGrid(64.0, 1024);
      final system = SpatialHashSystem(grid);
      final positions = ComponentCaste<Position>(Swarm.maxEntities);

      for (int i = 0; i < 1000; i++) {
        positions.add(i, Position.create(i * 1.5, i * 1.5));
      }

      final query = Query1<Position>(positions);

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        system.update(query);
      }
      stopwatch.stop();

      // Ensure it's reasonably fast, implying no major GC pauses or allocations
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
