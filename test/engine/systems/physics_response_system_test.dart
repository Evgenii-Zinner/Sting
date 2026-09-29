import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/circle_collider.dart';
import 'package:sting/engine/components/mass.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/physics_response_system.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';

void main() {
  group('PhysicsResponseSystem', () {
    late SpatialHashGrid grid;
    late ComponentStorage<Position> positionCaste;
    late ComponentStorage<Velocity> velocityCaste;
    late ComponentStorage<Mass> massCaste;
    late ComponentStorage<BoundingBox> boundingBoxCaste;
    late ComponentStorage<CircleCollider> circleColliderCaste;
    late PhysicsResponseSystem system;

    setUp(() {
      grid = SpatialHashGrid(64, 10);
      positionCaste = ComponentStorage<Position>(10);
      velocityCaste = ComponentStorage<Velocity>(10);
      massCaste = ComponentStorage<Mass>(10);
      boundingBoxCaste = ComponentStorage<BoundingBox>(10);
      circleColliderCaste = ComponentStorage<CircleCollider>(10);

      system = PhysicsResponseSystem(
        grid,
        positionCaste,
        velocityCaste,
        massCaste,
        boundingBoxCaste: boundingBoxCaste,
        circleColliderCaste: circleColliderCaste,
      );
    });

    test('Separates overlapping AABBs based on mass (Positional Correction)', () {
      positionCaste.add(1, Position.create(10, 10));
      boundingBoxCaste.add(1, BoundingBox.create(10, 10));
      massCaste.add(1, Mass.create(10)); // invMass = 0.1
      grid.insertPoint(1, 15, 15);

      positionCaste.add(2, Position.create(15, 10));
      boundingBoxCaste.add(2, BoundingBox.create(10, 10));
      massCaste.add(2, Mass.create(10)); // invMass = 0.1
      grid.insertPoint(2, 20, 15);

      system.update();

      expect(positionCaste.get(1)!.x, closeTo(10.0 - 1.996, 0.01));
      expect(positionCaste.get(2)!.x, closeTo(15.0 + 1.996, 0.01));
      expect(positionCaste.get(1)!.y, 10.0);
    });

    test('Infinite mass objects do not move during separation', () {
      positionCaste.add(1, Position.create(10, 10));
      boundingBoxCaste.add(1, BoundingBox.create(10, 10));
      massCaste.add(1, Mass.create(10)); // invMass = 0.1
      grid.insertPoint(1, 15, 15);

      positionCaste.add(2, Position.create(15, 10));
      boundingBoxCaste.add(2, BoundingBox.create(10, 10));
      massCaste.add(2, Mass.create(0)); // Static! invMass = 0
      grid.insertPoint(2, 20, 15);

      system.update();

      expect(positionCaste.get(1)!.x, closeTo(10.0 - (4.99 * 0.8), 0.01));
      expect(positionCaste.get(2)!.x, 15.0);
    });

    test('Bounces based on restitution (Velocity Impulse)', () {
      positionCaste.add(1, Position.create(10, 10));
      boundingBoxCaste.add(1, BoundingBox.create(10, 10));
      massCaste.add(1, Mass.create(1, restitution: 1.0));
      velocityCaste.add(1, Velocity.create(10, 0));
      grid.insertPoint(1, 15, 15);

      positionCaste.add(2, Position.create(15, 10));
      boundingBoxCaste.add(2, BoundingBox.create(10, 10));
      massCaste.add(2, Mass.create(1, restitution: 1.0));
      velocityCaste.add(2, Velocity.create(-10, 0));
      grid.insertPoint(2, 20, 15);

      system.update();

      expect(velocityCaste.get(1)!.dx, closeTo(-10, 0.1));
      expect(velocityCaste.get(2)!.dx, closeTo(10, 0.1));
    });

    test('Friction applies tangential impulse', () {
      positionCaste.add(1, Position.create(10, 10));
      boundingBoxCaste.add(1, BoundingBox.create(10, 10));
      massCaste.add(1, Mass.create(1, friction: 0.5));
      // Object hits exactly parallel with restitution 0. It should lose its tangential speed.
      velocityCaste.add(1, Velocity.create(10, 10));
      grid.insertPoint(1, 15, 15);

      positionCaste.add(2, Position.create(15, 10)); // Overlaps by 5, normal is X=1
      boundingBoxCaste.add(2, BoundingBox.create(10, 10));
      massCaste.add(2, Mass.create(0, friction: 0.5)); // infinite mass
      velocityCaste.add(2, Velocity.create(0, 0));
      grid.insertPoint(2, 20, 15);

      system.update();

      final vA = velocityCaste.get(1)!;

      // X velocity (normal) gets completely stopped (restitution 0)
      expect(vA.dx, closeTo(0.0, 0.001));
      // Y velocity gets reduced by friction (dynamic)
      expect(vA.dy, lessThan(10.0));
      expect(vA.dy, greaterThan(0.0));
    });

    test('Zero allocation check', () {
      for (int i = 0; i < 5; i++) {
        positionCaste.add(i, Position.create(10.0 * i, 10.0));
        boundingBoxCaste.add(i, BoundingBox.create(10, 10));
        massCaste.add(i, Mass.create(1));
        velocityCaste.add(i, Velocity.create(1, 0));
        grid.insertPoint(i, 10.0 * i + 5, 15.0);
      }

      final beforeMem = ProcessInfo.currentRss;
      for (int i = 0; i < 1000; i++) {
        system.update();
      }
      final afterMem = ProcessInfo.currentRss;

      expect(afterMem - beforeMem, lessThan(1024 * 1024 * 5));
    });
  });
}
