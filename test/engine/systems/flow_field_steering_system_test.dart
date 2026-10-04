import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/flow_field_follower.dart';
import 'package:sting/engine/systems/flow_field_steering_system.dart';
import 'dart:typed_data';

void main() {
  group('FlowFieldSteeringSystem', () {
    late Scene scene;
    late ComponentStorage<Position> positions;
    late ComponentStorage<Velocity> velocities;
    late ComponentStorage<FlowFieldFollower> followers;
    late FlowFieldSteeringSystem system;

    setUp(() {
      scene = Scene();
      positions = ComponentStorage<Position>(10);
      velocities = ComponentStorage<Velocity>(10);
      followers = ComponentStorage<FlowFieldFollower>(10);

      scene.registerStorage('Position', positions);
      scene.registerStorage('Velocity', velocities);
      scene.registerStorage('FlowFieldFollower', followers);

      system = FlowFieldSteeringSystem(
        positionCaste: positions,
        velocityCaste: velocities,
        flowFieldFollowerCaste: followers,
      );
    });

    test('Zero allocations during update', () {
      final entity = scene.createEntity();
      positions.add(entity, Position.create(10, 10));
      velocities.add(entity, Velocity.create(0, 0));
      followers.add(
        entity,
        FlowFieldFollower.create(
          alignmentWeight: 1.0,
          maxSpeed: 100.0,
          lookaheadDistance: 0.0,
        ),
      );

      system.flowFieldSampler = (double x, double y, Float32List out) {
        out[0] = 1.0;
        out[1] = 0.0;
      };

      // Warm up
      system.update(0.016);

      // Verify no allocations (logical run to ensure no exceptions or bounds issues)
      for (int i = 0; i < 1000; i++) {
        system.update(0.016);
      }
    });

    test('Smoothly steers towards streamline (alignmentWeight < 1.0)', () {
      final entity = scene.createEntity();
      positions.add(entity, Position.create(0, 0));
      velocities.add(entity, Velocity.create(0, 100)); // Moving up
      followers.add(
        entity,
        FlowFieldFollower.create(
          alignmentWeight: 0.5,
          maxSpeed: 100.0,
          lookaheadDistance: 0.0,
        ),
      );

      // Flow field points right
      system.flowFieldSampler = (double x, double y, Float32List out) {
        out[0] = 1.0;
        out[1] = 0.0;
      };

      system.update(0.016);

      final vel = velocities.get(entity)!;
      // Desired velocity is (100, 0).
      // current is (0, 100).
      // weight is 0.5.
      // dx += (100 - 0) * 0.5 = 50.
      // dy += (0 - 100) * 0.5 = -50. Resulting in dy = 50.
      // Clamped to 100:
      // (50, 50) has speed 70.71 < 100, so it shouldn't be clamped by maxSpeed, it will be (50, 50).
      expect(vel.dx, closeTo(50.0, 0.001));
      expect(vel.dy, closeTo(50.0, 0.001));
    });

    test('Clamps velocity to maxSpeed', () {
      final entity = scene.createEntity();
      positions.add(entity, Position.create(0, 0));
      velocities.add(entity, Velocity.create(0, 0));
      followers.add(
        entity,
        FlowFieldFollower.create(
          alignmentWeight: 1.0, // Instantly snaps to desired velocity
          maxSpeed: 50.0,
          lookaheadDistance: 0.0,
        ),
      );

      // Flow field points diagonally right-up
      system.flowFieldSampler = (double x, double y, Float32List out) {
        out[0] = 1.0;
        out[1] = 1.0;
      };

      system.update(0.016);

      final vel = velocities.get(entity)!;
      final speed = sqrt(vel.dx * vel.dx + vel.dy * vel.dy);
      expect(speed, closeTo(50.0, 0.001));
      expect(vel.dx, closeTo(vel.dy, 0.001));
    });

    test('Samples at lookahead distance based on velocity', () {
      final entity = scene.createEntity();
      positions.add(entity, Position.create(10, 20));
      velocities.add(entity, Velocity.create(30, 40)); // speed = 50, direction = (0.6, 0.8)
      followers.add(
        entity,
        FlowFieldFollower.create(
          alignmentWeight: 1.0,
          maxSpeed: 100.0,
          lookaheadDistance: 100.0,
        ),
      );

      double sampledX = 0;
      double sampledY = 0;

      system.flowFieldSampler = (double x, double y, Float32List out) {
        sampledX = x;
        sampledY = y;
        out[0] = 1.0;
        out[1] = 0.0;
      };

      system.update(0.016);

      // Position (10, 20) + Lookahead direction (0.6, 0.8) * 100 = (60, 80) => Expected (70, 100)
      expect(sampledX, closeTo(70.0, 0.001));
      expect(sampledY, closeTo(100.0, 0.001));
    });

    test('Does not update if flowFieldSampler is null', () {
      final entity = scene.createEntity();
      positions.add(entity, Position.create(0, 0));
      velocities.add(entity, Velocity.create(10, 10));
      followers.add(
        entity,
        FlowFieldFollower.create(
          alignmentWeight: 1.0,
          maxSpeed: 100.0,
          lookaheadDistance: 0.0,
        ),
      );

      system.update(0.016);

      final vel = velocities.get(entity)!;
      expect(vel.dx, 10.0);
      expect(vel.dy, 10.0);
    });

    test('Handles zero vector flow field without error', () {
      final entity = scene.createEntity();
      positions.add(entity, Position.create(0, 0));
      velocities.add(entity, Velocity.create(10, 10));
      followers.add(
        entity,
        FlowFieldFollower.create(
          alignmentWeight: 1.0,
          maxSpeed: 100.0,
          lookaheadDistance: 0.0,
        ),
      );

      system.flowFieldSampler = (double x, double y, Float32List out) {
        out[0] = 0.0;
        out[1] = 0.0;
      };

      system.update(0.016);

      final vel = velocities.get(entity)!;
      // Flow is zero, so desired velocity is zero. With weight 1.0, it should stop.
      expect(vel.dx, 0.0);
      expect(vel.dy, 0.0);
    });
  });
}
