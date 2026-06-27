import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/swarm.dart';

void main() {
  group('Swarm (Entity Manager)', () {
    late Swarm swarm;

    setUp(() {
      swarm = Swarm();
    });

    test('creates sequential entity IDs', () {
      expect(swarm.createEntity(), 0);
      expect(swarm.createEntity(), 1);
      expect(swarm.createEntity(), 2);
    });

    test('recycles destroyed entity IDs', () {
      final id1 = swarm.createEntity(); // 0
      final id2 = swarm.createEntity(); // 1
      final id3 = swarm.createEntity(); // 2

      expect(swarm.destroyEntity(id2), isTrue); // destroys 1

      final newId = swarm.createEntity();
      expect(newId, 1); // should reuse 1

      final newerId = swarm.createEntity();
      expect(newerId, 3); // next sequential is 3
    });

    test('returns false when destroying already destroyed entity', () {
      final id = swarm.createEntity();
      expect(swarm.destroyEntity(id), isTrue);
      expect(swarm.destroyEntity(id), isFalse); // double free
    });

    test('returns false when destroying invalid entity', () {
      expect(swarm.destroyEntity(-1), isFalse);
      expect(swarm.destroyEntity(Swarm.maxEntities), isFalse);
      expect(swarm.destroyEntity(Swarm.maxEntities + 1), isFalse);
    });

    test('returns false when destroying entity that was never created', () {
      expect(swarm.destroyEntity(0), isFalse);
      expect(swarm.destroyEntity(100), isFalse);
    });

    test('respects max entity limit', () {
      // Create max entities
      for (int i = 0; i < Swarm.maxEntities; i++) {
        expect(swarm.createEntity(), i);
      }

      // Try to create one more
      expect(swarm.createEntity(), -1);

      // Destroy one and recreate
      expect(swarm.destroyEntity(0), isTrue);
      expect(swarm.createEntity(), 0);

      // Try to create again
      expect(swarm.createEntity(), -1);
    });

    test('can destroy and recycle all entities multiple times', () {
      // First pass
      for (int i = 0; i < Swarm.maxEntities; i++) {
        swarm.createEntity();
      }
      for (int i = 0; i < Swarm.maxEntities; i++) {
        expect(swarm.destroyEntity(i), isTrue);
      }

      // Second pass
      for (int i = 0; i < Swarm.maxEntities; i++) {
        final id = swarm.createEntity();
        expect(id, isNot(-1));
      }
      expect(swarm.createEntity(), -1);
    });
  });
}
