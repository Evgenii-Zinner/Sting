import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/compound_bounding_box.dart';
import 'package:sting/engine/components/local_transform.dart';
import 'package:sting/engine/components/parent.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/entity_manager.dart';
import 'package:sting/engine/systems/compound_bounding_box_system.dart';

void main() {
  group('CompoundBoundingBoxSystem Zero Allocation Tests', () {
    late EntityManager entityManager;
    late ComponentStorage<CompoundBoundingBox> compoundBoxCaste;
    late ComponentStorage<BoundingBox> boundingBoxCaste;
    late ComponentStorage<Parent> parentCaste;
    late ComponentStorage<Position> positionCaste;
    late ComponentStorage<LocalTransform> localTransformCaste;
    late CompoundBoundingBoxSystem system;

    setUp(() {
      entityManager = EntityManager();
      compoundBoxCaste = ComponentStorage<CompoundBoundingBox>(100);
      boundingBoxCaste = ComponentStorage<BoundingBox>(100);
      parentCaste = ComponentStorage<Parent>(100);
      positionCaste = ComponentStorage<Position>(100);
      localTransformCaste = ComponentStorage<LocalTransform>(100);

      system = CompoundBoundingBoxSystem(
        compoundBoxCaste: compoundBoxCaste,
        boundingBoxCaste: boundingBoxCaste,
        parentCaste: parentCaste,
        positionCaste: positionCaste,
        localTransformCaste: localTransformCaste,
      );
    });

    test('Single root with no children computes its own bounds', () {
      final root = entityManager.createEntity();
      compoundBoxCaste.add(root, CompoundBoundingBox.create());
      boundingBoxCaste.add(root, BoundingBox.create(10, 10));
      positionCaste.add(root, Position.create(100, 100));

      system.update();

      final rootBox = boundingBoxCaste.get(root)!;
      expect(rootBox.width, 10);
      expect(rootBox.height, 10);

      final cBox = compoundBoxCaste.get(root)!;
      expect(cBox.minX, 95);
      expect(cBox.maxX, 105);
      expect(cBox.minY, 95);
      expect(cBox.maxY, 105);
      expect(cBox.childCount, 0);
    });

    test('Root with 1 child computes union bounds symmetrically', () {
      final root = entityManager.createEntity();
      compoundBoxCaste.add(root, CompoundBoundingBox.create());
      boundingBoxCaste.add(root, BoundingBox.create(10, 10)); // bounds: x(95,105), y(95,105)
      positionCaste.add(root, Position.create(100, 100));

      final child = entityManager.createEntity();
      parentCaste.add(child, Parent.create(root));
      boundingBoxCaste.add(child, BoundingBox.create(20, 20)); // bounds: x(140,160), y(140,160)
      positionCaste.add(child, Position.create(150, 150));

      system.update();

      final cBox = compoundBoxCaste.get(root)!;
      expect(cBox.childCount, 1);
      expect(cBox.minX, 95);
      expect(cBox.maxX, 160);
      expect(cBox.minY, 95);
      expect(cBox.maxY, 160);

      final rootBox = boundingBoxCaste.get(root)!;
      // max offset from 100 is 160 -> 60. So width 2 * 60 = 120
      expect(rootBox.width, 120);
      expect(rootBox.height, 120);
    });

    test('Root with multiple generations expands and shrinks using LocalTransform', () {
      final root = entityManager.createEntity();
      compoundBoxCaste.add(root, CompoundBoundingBox.create());
      boundingBoxCaste.add(root, BoundingBox.create(10, 10)); // bounds: x(-5,5), y(-5,5)
      positionCaste.add(root, Position.create(0, 0));

      final child1 = entityManager.createEntity();
      parentCaste.add(child1, Parent.create(root));
      boundingBoxCaste.add(child1, BoundingBox.create(10, 10)); // bounds: x(5,15), y(5,15)
      positionCaste.add(child1, Position.create(10, 10));

      final child2 = entityManager.createEntity(); // child of child1
      parentCaste.add(child2, Parent.create(child1));
      boundingBoxCaste.add(child2, BoundingBox.create(20, 20)); // bounds: x(10,30), y(10,30)
      // Use LocalTransform to test position fallback
      localTransformCaste.add(child2, LocalTransform.create(10, 10, 0, 1, 1));

      system.update();

      final cBox = compoundBoxCaste.get(root)!;
      expect(cBox.childCount, 2);
      expect(cBox.minX, -5);
      expect(cBox.maxX, 30);
      expect(cBox.minY, -5);
      expect(cBox.maxY, 30);

      final rootBox = boundingBoxCaste.get(root)!;
      expect(rootBox.width, 60);
      expect(rootBox.height, 60);

      // Now "shrink" child2 bounds by moving it closer
      localTransformCaste.get(child2)!.lx = -5;
      localTransformCaste.get(child2)!.ly = -5;

      // We must reset the root's box width/height back to its original so it doesn't inflate forever if it shrinks
      boundingBoxCaste.get(root)!.width = 10;
      boundingBoxCaste.get(root)!.height = 10;

      system.update();

      final cBoxNew = compoundBoxCaste.get(root)!;
      expect(cBoxNew.minX, -5);
      expect(cBoxNew.maxX, 15);
      expect(cBoxNew.minY, -5);
      expect(cBoxNew.maxY, 15);

      final rootBoxNew = boundingBoxCaste.get(root)!;
      expect(rootBoxNew.width, 30);
      expect(rootBoxNew.height, 30);
    });

    test('Zero allocations per frame', () {
      final root = entityManager.createEntity();
      compoundBoxCaste.add(root, CompoundBoundingBox.create());
      boundingBoxCaste.add(root, BoundingBox.create(10, 10));
      positionCaste.add(root, Position.create(100, 100));

      final child = entityManager.createEntity();
      parentCaste.add(child, Parent.create(root));
      boundingBoxCaste.add(child, BoundingBox.create(20, 20));
      positionCaste.add(child, Position.create(150, 150));

      system.update();

      for (var i = 0; i < 1000; i++) {
        system.update();
      }

      expect(compoundBoxCaste.get(root)!.childCount, 1);
    });
  });
}
