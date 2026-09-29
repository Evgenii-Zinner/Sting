import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/entity_pool.dart';
import 'package:sting/engine/ecs/prefab.dart';
import 'package:sting/engine/ecs/scene.dart';

void main() {
  group('EntityPool', () {
    late Scene scene;
    late Prefab prefab;
    int initCount = 0;

    setUp(() {
      scene = Scene();
      initCount = 0;
      prefab = Prefab((Scene s, int entity) {
        initCount++;
      });
    });

    test('spawn creates new entity when empty', () {
      final pool = EntityPool(scene: scene, prefab: prefab, capacity: 10);
      expect(pool.freeCount, equals(0));

      final entity = pool.spawn();
      expect(entity, isNot(-1));
      expect(initCount, equals(1));
      expect(pool.freeCount, equals(0));
    });

    test('populate pre-allocates entities', () {
      final pool = EntityPool(scene: scene, prefab: prefab, capacity: 10);

      final populated = pool.populate(5);
      expect(populated, equals(5));
      expect(pool.freeCount, equals(5));
      expect(initCount, equals(5));
    });

    test('populate respects capacity', () {
      final pool = EntityPool(scene: scene, prefab: prefab, capacity: 5);

      final populated = pool.populate(10);
      expect(populated, equals(5));
      expect(pool.freeCount, equals(5));
      expect(initCount, equals(5));
    });

    test('despawn pushes to free list', () {
      final pool = EntityPool(scene: scene, prefab: prefab, capacity: 10);
      final entity = pool.spawn(); // Should call prefab initializer

      final despawned = pool.despawn(entity);
      expect(despawned, isTrue);
      expect(pool.freeCount, equals(1));
    });

    test('spawn reuses entity from free list', () {
      final pool = EntityPool(scene: scene, prefab: prefab, capacity: 10);
      final entity1 = pool.spawn(); // Uses prefab.spawn, free count 0
      pool.despawn(entity1); // Pushes entity1 to free list, free count 1

      final beforeInitCount = initCount;
      final entity2 = pool.spawn(); // Should reuse entity1, free count 0

      expect(entity2, equals(entity1));
      expect(pool.freeCount, equals(0));
      expect(initCount,
          equals(beforeInitCount)); // Initializer not called again on reuse
    });

    test('despawn returns false when full', () {
      final pool = EntityPool(scene: scene, prefab: prefab, capacity: 2);
      pool.populate(2); // Fill to capacity
      expect(pool.freeCount, equals(2));

      final entity = scene.createEntity(); // Create independent entity
      final despawned = pool.despawn(entity);

      expect(despawned, isFalse);
      expect(pool.freeCount, equals(2)); // No change
    });
  });
}
