import 'dart:math';
import 'dart:typed_data';

import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/flow_field_follower.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';

/// Callback to sample the flow field at the given [x], [y] coordinates.
/// The sampled direction should be written into [outVector] at indices 0 and 1.
typedef FlowFieldSampler = void Function(
    double x, double y, Float32List outVector);

/// A system that steers entities along a flow field.
class FlowFieldSteeringSystem {
  final Query3<Position, Velocity, FlowFieldFollower> _query;

  /// The sampler function to query the vector field.
  FlowFieldSampler? flowFieldSampler;

  /// A pre-allocated buffer for zero-allocation sampling.
  final Float32List _sampleBuffer = Float32List(2);

  /// Creates a FlowFieldSteeringSystem.
  FlowFieldSteeringSystem({
    required ComponentStorage<Position> positionCaste,
    required ComponentStorage<Velocity> velocityCaste,
    required ComponentStorage<FlowFieldFollower> flowFieldFollowerCaste,
    this.flowFieldSampler,
  }) : _query = Query3<Position, Velocity, FlowFieldFollower>(
            positionCaste, velocityCaste, flowFieldFollowerCaste);

  /// Updates the velocities of all applicable entities by sampling the flow field.
  void update(double dt) {
    if (flowFieldSampler == null) return;

    _query.forEach((entity, position, velocity, follower) {
      double lookX = position.x;
      double lookY = position.y;

      // Determine lookahead position based on current velocity
      final double velSq =
          velocity.dx * velocity.dx + velocity.dy * velocity.dy;
      if (velSq > 0.0001) {
        final double speed = sqrt(velSq);
        lookX += (velocity.dx / speed) * follower.lookaheadDistance;
        lookY += (velocity.dy / speed) * follower.lookaheadDistance;
      }

      // Sample flow field at lookahead position
      _sampleBuffer[0] = 0.0;
      _sampleBuffer[1] = 0.0;
      flowFieldSampler!(lookX, lookY, _sampleBuffer);

      double flowX = _sampleBuffer[0];
      double flowY = _sampleBuffer[1];

      // Normalize the flow vector
      final double flowSq = flowX * flowX + flowY * flowY;
      if (flowSq > 0.0001) {
        final double flowMag = sqrt(flowSq);
        flowX /= flowMag;
        flowY /= flowMag;
      } else {
        flowX = 0.0;
        flowY = 0.0;
      }

      // Calculate desired velocity
      final double desiredVx = flowX * follower.maxSpeed;
      final double desiredVy = flowY * follower.maxSpeed;

      // Smoothly steer velocity towards desired velocity
      final double weight = follower.alignmentWeight.clamp(0.0, 1.0);

      velocity.dx += (desiredVx - velocity.dx) * weight;
      velocity.dy += (desiredVy - velocity.dy) * weight;

      // Clamp velocity to maxSpeed
      final double finalVelSq =
          velocity.dx * velocity.dx + velocity.dy * velocity.dy;
      if (finalVelSq > follower.maxSpeed * follower.maxSpeed) {
        final double finalSpeed = sqrt(finalVelSq);
        velocity.dx = (velocity.dx / finalSpeed) * follower.maxSpeed;
        velocity.dy = (velocity.dy / finalSpeed) * follower.maxSpeed;
      }
    });
  }
}
