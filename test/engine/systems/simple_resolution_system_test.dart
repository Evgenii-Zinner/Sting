import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/circle_collider.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/simple_resolution_system.dart';

void main() {
  group('SimpleResolutionSystem', () {
    late ComponentCaste<Position> positionCaste;
    late ComponentCaste<BoundingBox> boundingBoxCaste;
    late ComponentCaste<CircleCollider> circleColliderCaste;
    late SimpleResolutionSystem system;

    setUp(() {
      positionCaste = ComponentCaste<Position>(10);
      boundingBoxCaste = ComponentCaste<BoundingBox>(10);
      circleColliderCaste = ComponentCaste<CircleCollider>(10);

      system = SimpleResolutionSystem(
        positionCaste,
        boundingBoxCaste: boundingBoxCaste,
        circleColliderCaste: circleColliderCaste,
      );
    });

    group('resolveAABBAABB', () {
      test('Separates horizontally overlapping AABBs', () {
        positionCaste.add(1, Position.create(10, 10)); // Box A
        boundingBoxCaste.add(1, BoundingBox.create(10, 10));

        positionCaste.add(2, Position.create(18, 10)); // Box B (overlaps by 2 on X)
        boundingBoxCaste.add(2, BoundingBox.create(10, 10));

        system.resolveAABBAABB(1, 2);

        // Should push A left by 1 and B right by 1
        expect(positionCaste.get(1)!.x, closeTo(9.0, 0.001));
        expect(positionCaste.get(1)!.y, 10.0); // Y unchanged
        expect(positionCaste.get(2)!.x, closeTo(19.0, 0.001));
        expect(positionCaste.get(2)!.y, 10.0); // Y unchanged
      });

      test('Separates vertically overlapping AABBs', () {
        positionCaste.add(1, Position.create(10, 10)); // Box A
        boundingBoxCaste.add(1, BoundingBox.create(10, 10));

        positionCaste.add(2, Position.create(10, 16)); // Box B (overlaps by 4 on Y)
        boundingBoxCaste.add(2, BoundingBox.create(10, 10));

        system.resolveAABBAABB(1, 2);

        // Should push A up by 2 and B down by 2
        expect(positionCaste.get(1)!.y, closeTo(8.0, 0.001));
        expect(positionCaste.get(1)!.x, 10.0); // X unchanged
        expect(positionCaste.get(2)!.y, closeTo(18.0, 0.001));
        expect(positionCaste.get(2)!.x, 10.0); // X unchanged
      });

      test('Does nothing if AABBs are not overlapping', () {
        positionCaste.add(1, Position.create(10, 10)); // Box A
        boundingBoxCaste.add(1, BoundingBox.create(10, 10));

        positionCaste.add(2, Position.create(30, 30)); // Box B (far away)
        boundingBoxCaste.add(2, BoundingBox.create(10, 10));

        system.resolveAABBAABB(1, 2);

        // Positions should be unchanged
        expect(positionCaste.get(1)!.x, 10.0);
        expect(positionCaste.get(1)!.y, 10.0);
        expect(positionCaste.get(2)!.x, 30.0);
        expect(positionCaste.get(2)!.y, 30.0);
      });
    });

    group('resolveCircleCircle', () {
      test('Separates overlapping circles', () {
        positionCaste.add(1, Position.create(10, 10)); // Circle A
        circleColliderCaste.add(1, CircleCollider.create(5));

        positionCaste.add(2, Position.create(16, 10)); // Circle B (distance 6, radii sum 10, overlap 4)
        circleColliderCaste.add(2, CircleCollider.create(5));

        system.resolveCircleCircle(1, 2);

        // Should push A left by 2 and B right by 2
        expect(positionCaste.get(1)!.x, closeTo(8.0, 0.001));
        expect(positionCaste.get(1)!.y, 10.0);
        expect(positionCaste.get(2)!.x, closeTo(18.0, 0.001));
        expect(positionCaste.get(2)!.y, 10.0);
      });

      test('Separates exactly overlapping circles arbitrarily', () {
        positionCaste.add(1, Position.create(10, 10)); // Circle A
        circleColliderCaste.add(1, CircleCollider.create(5));

        positionCaste.add(2, Position.create(10, 10)); // Circle B exactly on A
        circleColliderCaste.add(2, CircleCollider.create(5));

        system.resolveCircleCircle(1, 2);

        // Should push apart arbitrarily without NaN (currently implemented as +/- 0.1 on X)
        expect(positionCaste.get(1)!.x, closeTo(9.9, 0.001));
        expect(positionCaste.get(2)!.x, closeTo(10.1, 0.001));
      });

      test('Does nothing if circles are not overlapping', () {
        positionCaste.add(1, Position.create(10, 10)); // Circle A
        circleColliderCaste.add(1, CircleCollider.create(5));

        positionCaste.add(2, Position.create(30, 10)); // Circle B far away
        circleColliderCaste.add(2, CircleCollider.create(5));

        system.resolveCircleCircle(1, 2);

        // Positions should be unchanged
        expect(positionCaste.get(1)!.x, 10.0);
        expect(positionCaste.get(2)!.x, 30.0);
      });
    });

    group('resolveAABBCircle', () {
      test('Separates circle overlapping right edge of AABB', () {
        positionCaste.add(1, Position.create(10, 10)); // Box A (10..20, 10..20)
        boundingBoxCaste.add(1, BoundingBox.create(10, 10));

        positionCaste.add(2, Position.create(22, 15)); // Circle B center (radius 4)
        circleColliderCaste.add(2, CircleCollider.create(4));

        // Closest point on AABB is (20, 15). Distance is 2. Overlap is 4 - 2 = 2.
        system.resolveAABBCircle(1, 2);

        // Should push Box A left by 1 and Circle B right by 1
        expect(positionCaste.get(1)!.x, closeTo(9.0, 0.001));
        expect(positionCaste.get(2)!.x, closeTo(23.0, 0.001));
        expect(positionCaste.get(1)!.y, 10.0); // Y unchanged
        expect(positionCaste.get(2)!.y, 15.0); // Y unchanged
      });

      test('Separates circle center completely inside AABB', () {
        positionCaste.add(1, Position.create(10, 10)); // Box A (10..20, 10..20)
        boundingBoxCaste.add(1, BoundingBox.create(10, 10));

        positionCaste.add(2, Position.create(18, 15)); // Circle B center inside box, radius 2
        circleColliderCaste.add(2, CircleCollider.create(2));

        // Center is at 18. Right edge is at 20. distToRight = 2.
        // It's closest to the right edge.
        // Needs to be pushed out by 2 (to get center out) + 2 (radius) = 4.
        // Shift is 2 each. Box left by 2, Circle right by 2.
        system.resolveAABBCircle(1, 2);

        expect(positionCaste.get(1)!.x, closeTo(8.0, 0.001));
        expect(positionCaste.get(2)!.x, closeTo(20.0, 0.001));
      });

      test('Does nothing if not overlapping', () {
        positionCaste.add(1, Position.create(10, 10)); // Box A
        boundingBoxCaste.add(1, BoundingBox.create(10, 10));

        positionCaste.add(2, Position.create(30, 30)); // Circle B far away
        circleColliderCaste.add(2, CircleCollider.create(2));

        system.resolveAABBCircle(1, 2);

        // Positions should be unchanged
        expect(positionCaste.get(1)!.x, 10.0);
        expect(positionCaste.get(2)!.x, 30.0);
      });
    });
  });
}
