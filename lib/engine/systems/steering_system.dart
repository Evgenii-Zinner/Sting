import 'dart:math';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/steering.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';

/// A system that calculates and applies steering forces to entities.
class SteeringSystem {
  final Query3<Position, Velocity, Steering> query;

  /// Creates a SteeringSystem querying entities with Position, Velocity, and Steering.
  SteeringSystem({
    required ComponentCaste<Position> positionCaste,
    required ComponentCaste<Velocity> velocityCaste,
    required ComponentCaste<Steering> steeringCaste,
  }) : query = Query3<Position, Velocity, Steering>(
            positionCaste, velocityCaste, steeringCaste);

  /// Updates the velocities of all applicable entities based on steering forces.
  void update(double dt) {
    query.forEach((entity, position, velocity, steering) {
      double desiredVx = 0.0;
      double desiredVy = 0.0;

      final double dx = steering.targetX - position.x;
      final double dy = steering.targetY - position.y;

      final double distSq = dx * dx + dy * dy;

      if (distSq > 0.000001) {
        final double dist = sqrt(distSq);
        final double dirX = dx / dist;
        final double dirY = dy / dist;

        if (steering.behavior == Steering.behaviorSeek) {
          desiredVx = dirX * steering.maxSpeed;
          desiredVy = dirY * steering.maxSpeed;
        } else if (steering.behavior == Steering.behaviorFlee) {
          desiredVx = -dirX * steering.maxSpeed;
          desiredVy = -dirY * steering.maxSpeed;
        } else if (steering.behavior == Steering.behaviorArrive) {
          double speed = steering.maxSpeed;
          if (dist < steering.decelerationRadius) {
            speed = steering.maxSpeed * (dist / steering.decelerationRadius);
          }
          desiredVx = dirX * speed;
          desiredVy = dirY * speed;
        }

        // Calculate steering force: steering = desired_velocity - velocity
        double steerForceX = desiredVx - velocity.dx;
        double steerForceY = desiredVy - velocity.dy;

        // Limit steering force to maxForce
        final double steerDistSq = steerForceX * steerForceX + steerForceY * steerForceY;
        if (steerDistSq > steering.maxForce * steering.maxForce) {
          final double steerDist = sqrt(steerDistSq);
          steerForceX = (steerForceX / steerDist) * steering.maxForce;
          steerForceY = (steerForceY / steerDist) * steering.maxForce;
        }

        // Apply steering force to velocity (assuming mass = 1 for simple steering)
        // a = F / m -> dv = F * dt (since m = 1)
        velocity.dx += steerForceX * dt;
        velocity.dy += steerForceY * dt;

        // Limit velocity to maxSpeed
        final double velSq = velocity.dx * velocity.dx + velocity.dy * velocity.dy;
        if (velSq > steering.maxSpeed * steering.maxSpeed) {
          final double speed = sqrt(velSq);
          velocity.dx = (velocity.dx / speed) * steering.maxSpeed;
          velocity.dy = (velocity.dy / speed) * steering.maxSpeed;
        }
      } else {
        // We are exactly at the target. If arrive, stop.
        if (steering.behavior == Steering.behaviorArrive) {
           double steerForceX = -velocity.dx;
           double steerForceY = -velocity.dy;

           final double steerDistSq = steerForceX * steerForceX + steerForceY * steerForceY;
           if (steerDistSq > steering.maxForce * steering.maxForce) {
             final double steerDist = sqrt(steerDistSq);
             steerForceX = (steerForceX / steerDist) * steering.maxForce;
             steerForceY = (steerForceY / steerDist) * steering.maxForce;
           }
           velocity.dx += steerForceX * dt;
           velocity.dy += steerForceY * dt;
        }
      }
    });
  }
}
