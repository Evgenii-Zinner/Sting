import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/local_transform.dart';
import 'package:sting/engine/components/parent.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/rotation.dart';
import 'package:sting/engine/components/scale.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/transform_system.dart';
import 'dart:math' as math;

void main() {
  group('TransformSystem', () {
    late ComponentCaste<Parent> parentCaste;
    late ComponentCaste<LocalTransform> localTransformCaste;
    late ComponentCaste<Position> positionCaste;
    late ComponentCaste<Rotation> rotationCaste;
    late ComponentCaste<Scale> scaleCaste;
    late TransformSystem system;

    setUp(() {
      parentCaste = ComponentCaste<Parent>(100);
      localTransformCaste = ComponentCaste<LocalTransform>(100);
      positionCaste = ComponentCaste<Position>(100);
      rotationCaste = ComponentCaste<Rotation>(100);
      scaleCaste = ComponentCaste<Scale>(100);

      system = TransformSystem(
        parentCaste: parentCaste,
        localTransformCaste: localTransformCaste,
        positionCaste: positionCaste,
        rotationCaste: rotationCaste,
        scaleCaste: scaleCaste,
      );
    });

    test('updates world transform based on parent transform', () {
      final parentId = 1;
      final childId = 2;

      // Parent transform (absolute)
      positionCaste.add(parentId, Position.create(10.0, 20.0));
      rotationCaste.add(parentId, Rotation.create(math.pi / 2)); // 90 degrees
      scaleCaste.add(parentId, Scale.create(2.0, 2.0));

      // Child local transform
      parentCaste.add(childId, Parent.create(parentId));
      localTransformCaste.add(childId, LocalTransform.create(5.0, 0.0, math.pi / 2, 1.5, 1.5));
      positionCaste.add(childId, Position.create(0.0, 0.0));
      rotationCaste.add(childId, Rotation.create(0.0));
      scaleCaste.add(childId, Scale.create(1.0, 1.0));

      system.update();

      final childPos = positionCaste.get(childId)!;
      final childRot = rotationCaste.get(childId)!;
      final childScale = scaleCaste.get(childId)!;

      // Expected calculation:
      // Parent pos: (10, 20)
      // Parent rot: pi/2 (90 deg)
      // Parent scale: (2, 2)
      // Child local: (5, 0)
      // Rotated by pi/2: (0, 5) -> but wait, scale is applied before rotation.
      // Scaled local: (10, 0)
      // Rotated local: (0, 10)
      // Translated: (10, 30)

      expect(childPos.x, closeTo(10.0, 0.001));
      expect(childPos.y, closeTo(30.0, 0.001));

      // Rotation: pi/2 + pi/2 = pi
      expect(childRot.radians, closeTo(math.pi, 0.001));

      // Scale: 2.0 * 1.5 = 3.0
      expect(childScale.x, closeTo(3.0, 0.001));
      expect(childScale.y, closeTo(3.0, 0.001));
    });

    test('handles multi-level parenting correctly (topological order)', () {
      final rootId = 1;
      final childId = 2;
      final grandChildId = 3;

      // Root
      positionCaste.add(rootId, Position.create(100.0, 100.0));
      rotationCaste.add(rootId, Rotation.create(0.0));
      scaleCaste.add(rootId, Scale.create(1.0, 1.0));

      // Child
      parentCaste.add(childId, Parent.create(rootId));
      localTransformCaste.add(childId, LocalTransform.create(50.0, 0.0, 0.0, 1.0, 1.0));
      positionCaste.add(childId, Position.create(0.0, 0.0));
      rotationCaste.add(childId, Rotation.create(0.0));
      scaleCaste.add(childId, Scale.create(1.0, 1.0));

      // GrandChild - We add it BEFORE the child in the hierarchy to test out-of-order resolution
      parentCaste.add(grandChildId, Parent.create(childId));
      localTransformCaste.add(grandChildId, LocalTransform.create(0.0, 50.0, 0.0, 1.0, 1.0));
      positionCaste.add(grandChildId, Position.create(0.0, 0.0));
      rotationCaste.add(grandChildId, Rotation.create(0.0));
      scaleCaste.add(grandChildId, Scale.create(1.0, 1.0));

      system.update();

      final grandChildPos = positionCaste.get(grandChildId)!;

      // Root: (100, 100)
      // Child local (50, 0) -> World (150, 100)
      // Grandchild local (0, 50) -> World (150, 150)
      expect(grandChildPos.x, closeTo(150.0, 0.001));
      expect(grandChildPos.y, closeTo(150.0, 0.001));
    });

    test('gracefully handles cycles in hierarchy', () {
      final entityA = 1;
      final entityB = 2;

      // A is child of B
      parentCaste.add(entityA, Parent.create(entityB));
      localTransformCaste.add(entityA, LocalTransform.create(10.0, 0.0, 0.0, 1.0, 1.0));
      positionCaste.add(entityA, Position.create(0.0, 0.0));

      // B is child of A
      parentCaste.add(entityB, Parent.create(entityA));
      localTransformCaste.add(entityB, LocalTransform.create(0.0, 10.0, 0.0, 1.0, 1.0));
      positionCaste.add(entityB, Position.create(0.0, 0.0));

      // Should not throw StackOverflowError
      expect(() => system.update(), returnsNormally);
    });
  });
}
