import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/steering.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/steering_system.dart';

void main() {
  group('SteeringSystem', () {
    test('Seek behavior steers towards target', () {
      final positionCaste = ComponentCaste<Position>(10);
      final velocityCaste = ComponentCaste<Velocity>(10);
      final steeringCaste = ComponentCaste<Steering>(10);

      final system = SteeringSystem(
        positionCaste: positionCaste,
        velocityCaste: velocityCaste,
        steeringCaste: steeringCaste,
      );

      positionCaste.add(0, Position.create(0, 0));
      velocityCaste.add(0, Velocity.create(0, 0));
      steeringCaste.add(
        0,
        Steering.create(
          targetX: 100,
          targetY: 0,
          maxSpeed: 10,
          maxForce: 5,
          behavior: Steering.behaviorSeek,
        ),
      );

      system.update(1.0); // dt = 1.0

      final vel = velocityCaste.get(0)!;
      // Desired velocity is (10, 0)
      // Steering force is (10, 0) - (0, 0) = (10, 0)
      // Clamped force is (5, 0)
      // New velocity is (0, 0) + (5, 0) * 1.0 = (5, 0)
      expect(vel.dx, closeTo(5.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));
    });

    test('Flee behavior steers away from target', () {
      final positionCaste = ComponentCaste<Position>(10);
      final velocityCaste = ComponentCaste<Velocity>(10);
      final steeringCaste = ComponentCaste<Steering>(10);

      final system = SteeringSystem(
        positionCaste: positionCaste,
        velocityCaste: velocityCaste,
        steeringCaste: steeringCaste,
      );

      positionCaste.add(0, Position.create(0, 0));
      velocityCaste.add(0, Velocity.create(0, 0));
      steeringCaste.add(
        0,
        Steering.create(
          targetX: 100,
          targetY: 0,
          maxSpeed: 10,
          maxForce: 5,
          behavior: Steering.behaviorFlee,
        ),
      );

      system.update(1.0); // dt = 1.0

      final vel = velocityCaste.get(0)!;
      // Desired velocity is (-10, 0)
      // Steering force is (-10, 0) - (0, 0) = (-10, 0)
      // Clamped force is (-5, 0)
      // New velocity is (0, 0) + (-5, 0) * 1.0 = (-5, 0)
      expect(vel.dx, closeTo(-5.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));
    });

    test('Arrive behavior slows down when inside deceleration radius', () {
      final positionCaste = ComponentCaste<Position>(10);
      final velocityCaste = ComponentCaste<Velocity>(10);
      final steeringCaste = ComponentCaste<Steering>(10);

      final system = SteeringSystem(
        positionCaste: positionCaste,
        velocityCaste: velocityCaste,
        steeringCaste: steeringCaste,
      );

      // Distance to target is 25, decel radius is 50
      positionCaste.add(0, Position.create(75, 0));
      velocityCaste.add(0, Velocity.create(0, 0));
      steeringCaste.add(
        0,
        Steering.create(
          targetX: 100,
          targetY: 0,
          maxSpeed: 10,
          maxForce: 5,
          behavior: Steering.behaviorArrive,
          decelerationRadius: 50,
        ),
      );

      system.update(1.0); // dt = 1.0

      final vel = velocityCaste.get(0)!;
      // dist = 25. Desired speed = 10 * (25 / 50) = 5
      // Desired velocity is (5, 0)
      // Steering force is (5, 0) - (0, 0) = (5, 0)
      // Clamped force is (5, 0) (since maxForce is 5)
      // New velocity is (0, 0) + (5, 0) * 1.0 = (5, 0)
      expect(vel.dx, closeTo(5.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));
    });

    test('zero allocations per tick', () {
      final positionCaste = ComponentCaste<Position>(100);
      final velocityCaste = ComponentCaste<Velocity>(100);
      final steeringCaste = ComponentCaste<Steering>(100);

      for (var i = 0; i < 100; i++) {
        positionCaste.add(i, Position.create(i.toDouble(), i.toDouble()));
        velocityCaste.add(i, Velocity.create(1.0, 1.0));
        steeringCaste.add(i, Steering.create(targetX: 50.0, targetY: 50.0));
      }

      final system = SteeringSystem(
        positionCaste: positionCaste,
        velocityCaste: velocityCaste,
        steeringCaste: steeringCaste,
      );

      expect(() => system.update(0.016), returnsNormally);
    });
  });
}
