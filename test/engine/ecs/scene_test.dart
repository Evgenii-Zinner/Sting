import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/swarm.dart';

void main() {
  group('Scene', () {
    late Scene scene;
    late ComponentCaste<Position> positionCaste;
    late ComponentCaste<Velocity> velocityCaste;

    setUp(() {
      scene = Scene();
      positionCaste = ComponentCaste<Position>(100);
      velocityCaste = ComponentCaste<Velocity>(100);
    });

    test('can register and retrieve castes', () {
      scene.registerCaste<Position>('Position', positionCaste);

      expect(scene.getCaste<Position>('Position'), equals(positionCaste));
    });

    test('throws StateError if caste is already registered', () {
      scene.registerCaste<Position>('Position', positionCaste);

      expect(() => scene.registerCaste<Position>('Position', positionCaste),
          throwsStateError);
    });

    test('throws StateError if caste is not registered', () {
      expect(() => scene.getCaste<Position>('Position'), throwsStateError);
    });

    test('createEntity delegates to Swarm', () {
      final entity1 = scene.createEntity();
      final entity2 = scene.createEntity();

      expect(entity1, 0);
      expect(entity2, 1);
    });

    test('destroyEntity cleanly removes components from registered castes', () {
      scene.registerCaste<Position>('Position', positionCaste);
      scene.registerCaste<Velocity>('Velocity', velocityCaste);

      final entity1 = scene.createEntity(); // 0
      final entity2 = scene.createEntity(); // 1

      positionCaste.add(entity1, Position.create(10, 20));
      velocityCaste.add(entity1, Velocity.create(1, 1));

      positionCaste.add(entity2, Position.create(30, 40));
      // Entity 2 does not have velocity

      expect(positionCaste.get(entity1), isNotNull);
      expect(velocityCaste.get(entity1), isNotNull);

      // Destroy entity 1
      expect(scene.destroyEntity(entity1), isTrue);

      // Ensure entity 1's components are removed
      expect(positionCaste.get(entity1), isNull);
      expect(velocityCaste.get(entity1), isNull);

      // Ensure entity 2 is unaffected
      expect(positionCaste.get(entity2), isNotNull);
    });

    test('destroyEntity returns false for invalid entity', () {
      scene.registerCaste<Position>('Position', positionCaste);

      expect(scene.destroyEntity(-1), isFalse);
      expect(scene.destroyEntity(Swarm.maxEntities), isFalse);
      expect(scene.destroyEntity(10), isFalse); // Never created
    });
  });
}
