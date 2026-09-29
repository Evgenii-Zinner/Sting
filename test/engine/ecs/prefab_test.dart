import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/prefab.dart';
import 'package:sting/engine/ecs/scene.dart';

void main() {
  group('Prefab', () {
    test('spawn creates an entity and calls initializer', () {
      final scene = Scene();
      final caste = ComponentCaste<String>(100);
      scene.registerCaste('StringCaste', caste);

      int initializedEntity = -1;
      bool initializerCalled = false;

      final prefab = Prefab((Scene s, int entity) {
        initializerCalled = true;
        initializedEntity = entity;
        final c = s.getCaste<String>('StringCaste');
        c.add(entity, 'SpawnedComponent');
      });

      final entity = prefab.spawn(scene);

      expect(entity, isNot(-1));
      expect(initializerCalled, isTrue);
      expect(initializedEntity, equals(entity));

      final c = scene.getCaste<String>('StringCaste');
      expect(c.get(entity), equals('SpawnedComponent'));
    });
  });
}
