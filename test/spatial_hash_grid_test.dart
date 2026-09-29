import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';
import 'package:sting/engine/ecs/entity_manager.dart';

void main() {
  group('SpatialHashGrid', () {
    test('inserts and queries point', () {
      final grid = SpatialHashGrid(64.0, 1024);

      grid.insertPoint(1, 10.0, 10.0);
      grid.insertPoint(2, 20.0, 20.0);
      grid.insertPoint(3, 100.0, 100.0); // Different cell

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

      grid.insertPoint(1, 10.0, 10.0);
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
      grid.insertPoint(1, 10.0, 10.0);
      // Cell (1, 0)
      grid.insertPoint(2, 70.0, 10.0);
      // Cell (0, 1)
      grid.insertPoint(3, 10.0, 70.0);
      // Cell (2, 2)
      grid.insertPoint(4, 150.0, 150.0);

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
      grid.insertPoint(5, -10.0, -10.0);
      grid.insertPoint(6, -20.0, -20.0);

      final found = <int>[];
      grid.queryPoint(-15.0, -15.0, (entity) {
        found.add(entity);
      });

      expect(found, containsAll([5, 6]));
      expect(found.length, 2);
    });

    test('throws RangeError on invalid entity ID', () {
      final grid = SpatialHashGrid(64.0, 1024);
      expect(() => grid.insertPoint(-1, 0.0, 0.0), throwsRangeError);
      expect(() => grid.insertPoint(EntityManager.maxEntities, 0.0, 0.0), throwsRangeError);
    });

    test('queryAABB accurate broad-phase collision candidates', () {
      final grid = SpatialHashGrid(64.0, 1024);

      // Target object bounding box: (100, 100) -> width 30, height 30 => box(100, 100, 130, 130)
      // Cells: (1, 1), (2, 1), (1, 2), (2, 2)

      // Inside candidate
      grid.insertPoint(1, 110.0, 110.0);

      // Touching boundary candidate
      grid.insertPoint(2, 90.0, 90.0);

      // Inside cell but outside exact rect candidate (still broad-phase candidate)
      grid.insertPoint(3, 70.0, 70.0);

      // Far away, not a candidate
      grid.insertPoint(4, 300.0, 300.0);

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

    test('insertAABB adds entity to multiple cells and query deduplicates', () {
      final grid = SpatialHashGrid(64.0, 1024);

      // Entity bounds from 10 to 100, spans cell (0,0) and (1,1)
      grid.insertAABB(1, 10.0, 10.0, 100.0, 100.0);

      // Verify it's in cell (0,0)
      final foundIn00 = <int>[];
      grid.queryPoint(15.0, 15.0, (entity) {
        foundIn00.add(entity);
      });
      expect(foundIn00, contains(1));

      // Verify it's in cell (1,1)
      final foundIn11 = <int>[];
      grid.queryPoint(80.0, 80.0, (entity) {
        foundIn11.add(entity);
      });
      expect(foundIn11, contains(1));

      // Query whole area, should only yield entity 1 once due to deduplication
      final foundAABB = <int>[];
      grid.queryAABB(0.0, 0.0, 128.0, 128.0, (entity) {
        foundAABB.add(entity);
        return true;
      });
      expect(foundAABB, [1]);
    });

    test('query layer mask filtering', () {
      final grid = SpatialHashGrid(64.0, 1024);

      // Layer 1
      grid.insertPoint(1, 10.0, 10.0, 1);
      // Layer 2
      grid.insertPoint(2, 10.0, 10.0, 2);
      // Layer 3 (1 | 2)
      grid.insertPoint(3, 10.0, 10.0, 3);
      // Layer 4
      grid.insertPoint(4, 10.0, 10.0, 4);

      // Query only layer 1
      final foundLayer1 = <int>[];
      grid.queryPoint(10.0, 10.0, (entity) {
        foundLayer1.add(entity);
      }, 1);
      expect(foundLayer1, containsAll([1, 3]));
      expect(foundLayer1.length, 2);

      // Query only layer 2
      final foundLayer2 = <int>[];
      grid.queryPoint(10.0, 10.0, (entity) {
        foundLayer2.add(entity);
      }, 2);
      expect(foundLayer2, containsAll([2, 3]));
      expect(foundLayer2.length, 2);

      // Query layer 4
      final foundLayer4 = <int>[];
      grid.queryPoint(10.0, 10.0, (entity) {
        foundLayer4.add(entity);
      }, 4);
      expect(foundLayer4, [4]);

      // Query layer 1 & 4 (mask = 5)
      final foundLayer1_4 = <int>[];
      grid.queryPoint(10.0, 10.0, (entity) {
        foundLayer1_4.add(entity);
      }, 5);
      expect(foundLayer1_4, containsAll([1, 3, 4]));
      expect(foundLayer1_4.length, 3);
    });

    test('queryRadius broad-phase coverage', () {
      final grid = SpatialHashGrid(64.0, 1024);

      // Center is at (100, 100). Radius 30.
      // Bounds: (70, 70) to (130, 130).

      // Inside circle
      grid.insertPoint(1, 100.0, 100.0);

      // Inside bounding box, outside circle (broad-phase will still catch it)
      grid.insertPoint(2, 70.0, 70.0);

      // Outside bounding box
      grid.insertPoint(3, 10.0, 10.0);

      final found = <int>[];
      grid.queryRadius(100.0, 100.0, 30.0, (entity) {
        found.add(entity);
        return true;
      });

      expect(found, containsAll([1, 2]));
      expect(found.length, 2);
      expect(found.contains(3), isFalse);
    });
  });
}
