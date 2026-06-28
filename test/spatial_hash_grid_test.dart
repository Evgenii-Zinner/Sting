import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';
import 'package:sting/engine/ecs/swarm.dart';

void main() {
  group('SpatialHashGrid', () {
    test('inserts and queries point', () {
      final grid = SpatialHashGrid(64.0, 1024);

      grid.insert(1, 10.0, 10.0);
      grid.insert(2, 20.0, 20.0);
      grid.insert(3, 100.0, 100.0); // Different cell

      final found = <int>[];
      grid.queryPoint(15.0, 15.0, (entity) {
        found.add(entity);
      });

      // It should find entities 1 and 2, which are in cell (0, 0)
      expect(found, containsAll([1, 2]));
      expect(found.length, 2);
    });

    test('clears grid', () {
      final grid = SpatialHashGrid(64.0, 1024);

      grid.insert(1, 10.0, 10.0);
      grid.clear();

      final found = <int>[];
      grid.queryPoint(10.0, 10.0, (entity) {
        found.add(entity);
      });

      expect(found, isEmpty);
    });

    test('queryAABB returns entities in overlapping cells', () {
      final grid = SpatialHashGrid(64.0, 1024);

      // Cell (0, 0)
      grid.insert(1, 10.0, 10.0);
      // Cell (1, 0)
      grid.insert(2, 70.0, 10.0);
      // Cell (0, 1)
      grid.insert(3, 10.0, 70.0);
      // Cell (2, 2)
      grid.insert(4, 150.0, 150.0);

      final found = <int>[];
      grid.queryAABB(0.0, 0.0, 100.0, 100.0, (entity) {
        found.add(entity);
        return true;
      });

      // Box from (0,0) to (100,100) overlaps cells (0,0), (1,0), (0,1), (1,1)
      // Entities 1, 2, 3 should be found
      expect(found, containsAll([1, 2, 3]));
      expect(found.length, 3);
      expect(found.contains(4), isFalse);
    });

    test('handles negative coordinates correctly', () {
      final grid = SpatialHashGrid(64.0, 1024);

      // Cell (-1, -1) -> hash of (-1, -1)
      grid.insert(5, -10.0, -10.0);
      grid.insert(6, -20.0, -20.0);

      final found = <int>[];
      grid.queryPoint(-15.0, -15.0, (entity) {
        found.add(entity);
      });

      expect(found, containsAll([5, 6]));
      expect(found.length, 2);
    });

    test('throws RangeError on invalid entity ID', () {
      final grid = SpatialHashGrid(64.0, 1024);
      expect(() => grid.insert(-1, 0.0, 0.0), throwsRangeError);
      expect(() => grid.insert(Swarm.maxEntities, 0.0, 0.0), throwsRangeError);
    });

    test('queryAABB accurate broad-phase collision candidates', () {
      final grid = SpatialHashGrid(64.0, 1024);

      // Target object bounding box: (100, 100) -> width 30, height 30 => box(100, 100, 130, 130)
      // Cells: (1, 1), (2, 1), (1, 2), (2, 2)

      // Inside candidate
      grid.insert(1, 110.0, 110.0);

      // Touching boundary candidate
      grid.insert(2, 90.0, 90.0);

      // Inside cell but outside exact rect candidate (still broad-phase candidate)
      grid.insert(3, 70.0, 70.0);

      // Far away, not a candidate
      grid.insert(4, 300.0, 300.0);

      final found = <int>[];
      grid.queryAABB(100.0, 100.0, 30.0, 30.0, (entity) {
        found.add(entity);
        return true;
      });

      // (100,100) to (130,130) spans cell(1,1) to cell(2,2).
      // Entity 1 is at 110,110 (cell 1,1).
      // Entity 2 is at 90,90 (cell 1,1).
      // Entity 3 is at 70,70 (cell 1,1).
      // Entity 4 is at 300,300 (cell 4,4).

      // We expect 1, 2, 3 to be found, but not 4.
      expect(found, containsAll([1, 2, 3]));
      expect(found.length, 3);
      expect(found.contains(4), isFalse);
    });
  });
}
