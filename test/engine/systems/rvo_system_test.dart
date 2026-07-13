import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/circle_collider.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/preferred_velocity.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/rvo_system.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';

void main() {
  group('RVOSystem Tests', () {
    late SpatialHashGrid grid;
    late ComponentCaste<Position> positionCaste;
    late ComponentCaste<Velocity> velocityCaste;
    late ComponentCaste<PreferredVelocity> preferredVelocityCaste;
    late ComponentCaste<CircleCollider> circleColliderCaste;
    late RVOSystem system;

    setUp(() {
      grid = SpatialHashGrid(100.0, 100);
      positionCaste = ComponentCaste<Position>(10);
      velocityCaste = ComponentCaste<Velocity>(10);
      preferredVelocityCaste = ComponentCaste<PreferredVelocity>(10);
      circleColliderCaste = ComponentCaste<CircleCollider>(10);

      system = RVOSystem(
        grid,
        positionCaste,
        velocityCaste,
        preferredVelocityCaste,
        circleColliderCaste,
        timeHorizon: 2.0,
        maxSpeed: 100.0,
        neighborDist: 150.0,
      );
    });

    test('agents traveling head-on resolve collisions by steering (cross-product bias)', () {
      // Agent 0 moving Right
      final pos0 = Position.create(0.0, 0.0);
      positionCaste.add(0, pos0);
      velocityCaste.add(0, Velocity.create(50.0, 0.0));
      preferredVelocityCaste.add(0, PreferredVelocity.create(50.0, 0.0));
      circleColliderCaste.add(0, CircleCollider.create(10.0));
      grid.insert(0, pos0.x, pos0.y);

      // Agent 1 moving Left
      final pos1 = Position.create(80.0, 0.0);
      positionCaste.add(1, pos1);
      velocityCaste.add(1, Velocity.create(-50.0, 0.0));
      preferredVelocityCaste.add(1, PreferredVelocity.create(-50.0, 0.0));
      circleColliderCaste.add(1, CircleCollider.create(10.0));
      grid.insert(1, pos1.x, pos1.y);

      // They will collide in 0.8 seconds (distance 80, rel speed 100). Horizon is 2.0.
      system.update(0.1);

      final v0 = velocityCaste.get(0)!;
      final v1 = velocityCaste.get(1)!;

      // Ensure they applied a steering penalty on the Y axis
      expect(v0.dy, isNot(closeTo(0.0, 0.0001)));
      expect(v1.dy, isNot(closeTo(0.0, 0.0001)));

      // Since they are exactly head-on, cross product is 0.
      // Right hand passing bias: when cross >= 0, repDirX = -relVy/relDist (0), repDirY = relVx/relDist
      // For Agent 0: relVx = 50 - (-50) = 100, relVy = 0.
      // cross = 100 * 0 - 0 * 80 = 0.
      // repDirX = 0, repDirY = 1.
      // Thus Agent 0 should turn right (positive Y).
      expect(v0.dy, greaterThan(0.0));
    });

    test('agent avoids a stationary agent', () {
      final pos0 = Position.create(0.0, 0.0);
      positionCaste.add(0, pos0);
      velocityCaste.add(0, Velocity.create(50.0, 0.0));
      preferredVelocityCaste.add(0, PreferredVelocity.create(50.0, 0.0));
      circleColliderCaste.add(0, CircleCollider.create(10.0));
      grid.insert(0, pos0.x, pos0.y);

      final pos1 = Position.create(50.0, 0.0);
      positionCaste.add(1, pos1);
      velocityCaste.add(1, Velocity.create(0.0, 0.0));
      preferredVelocityCaste.add(1, PreferredVelocity.create(0.0, 0.0));
      circleColliderCaste.add(1, CircleCollider.create(10.0));
      grid.insert(1, pos1.x, pos1.y);

      system.update(0.1);

      final v0 = velocityCaste.get(0)!;
      final v1 = velocityCaste.get(1)!;

      // Agent 0 should steer to avoid stationary Agent 1
      expect(v0.dy, isNot(closeTo(0.0, 0.0001)));
      expect(v0.dy, greaterThan(0.0));

      // Agent 1 should also react, trying to get out of the way.
      // Reciprocal avoidance means both agents take half the effort.
      expect(v1.dy, isNot(closeTo(0.0, 0.0001)));
    });

    test('agents moving away from each other do not steer', () {
      final pos0 = Position.create(0.0, 0.0);
      positionCaste.add(0, pos0);
      velocityCaste.add(0, Velocity.create(-50.0, 0.0));
      preferredVelocityCaste.add(0, PreferredVelocity.create(-50.0, 0.0));
      circleColliderCaste.add(0, CircleCollider.create(10.0));
      grid.insert(0, pos0.x, pos0.y);

      final pos1 = Position.create(80.0, 0.0);
      positionCaste.add(1, pos1);
      velocityCaste.add(1, Velocity.create(50.0, 0.0));
      preferredVelocityCaste.add(1, PreferredVelocity.create(50.0, 0.0));
      circleColliderCaste.add(1, CircleCollider.create(10.0));
      grid.insert(1, pos1.x, pos1.y);

      system.update(0.1);

      final v0 = velocityCaste.get(0)!;
      final v1 = velocityCaste.get(1)!;

      // No steering should occur since they are moving apart
      expect(v0.dx, closeTo(-50.0, 0.0001));
      expect(v0.dy, closeTo(0.0, 0.0001));

      expect(v1.dx, closeTo(50.0, 0.0001));
      expect(v1.dy, closeTo(0.0, 0.0001));
    });

    test('agents on parallel paths that do not intersect do not steer', () {
      // Agent 0 moving Right at y=30
      final pos0 = Position.create(0.0, 30.0);
      positionCaste.add(0, pos0);
      velocityCaste.add(0, Velocity.create(50.0, 0.0));
      preferredVelocityCaste.add(0, PreferredVelocity.create(50.0, 0.0));
      circleColliderCaste.add(0, CircleCollider.create(10.0));
      grid.insert(0, pos0.x, pos0.y);

      // Agent 1 moving Left at y=-30
      final pos1 = Position.create(80.0, -30.0);
      positionCaste.add(1, pos1);
      velocityCaste.add(1, Velocity.create(-50.0, 0.0));
      preferredVelocityCaste.add(1, PreferredVelocity.create(-50.0, 0.0));
      circleColliderCaste.add(1, CircleCollider.create(10.0));
      grid.insert(1, pos1.x, pos1.y);

      // They will pass each other with a y-distance of 60. Combined radii is 20.
      // So cpaDistSq (3600) > radiusSq (400), no collision expected.
      system.update(0.1);

      final v0 = velocityCaste.get(0)!;
      final v1 = velocityCaste.get(1)!;

      // No steering should occur since their CPA distance is safely larger than combined radii
      expect(v0.dx, closeTo(50.0, 0.0001));
      expect(v0.dy, closeTo(0.0, 0.0001));

      expect(v1.dx, closeTo(-50.0, 0.0001));
      expect(v1.dy, closeTo(0.0, 0.0001));
    });
  });
}
