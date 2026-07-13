import 'dart:math';
import 'dart:typed_data';

import 'package:sting/engine/components/circle_collider.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/preferred_velocity.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';

/// A system that implements predictive reciprocal collision avoidance (RVO/ORCA)
/// in 2D continuous space to allow multiple agents to navigate without overlapping.
class RVOSystem {
  final SpatialHashGrid _grid;
  final ComponentCaste<Position> _positionCaste;
  final ComponentCaste<Velocity> _velocityCaste;
  final ComponentCaste<PreferredVelocity> _preferredVelocityCaste;
  final ComponentCaste<CircleCollider> _circleColliderCaste;

  final double _timeHorizon;
  final double _maxSpeed;
  final double _neighborDist;

  // Buffer to store new velocities to update simultaneously after all calculations
  // Expand buffer if entity IDs exceed this dynamically, but Sting has a 65535 limit
  // from Uint16List usage in castes. We allocate a bit more just in case.
  late Float32List _newVelocities;

  /// Creates a new RVOSystem.
  RVOSystem(
    this._grid,
    this._positionCaste,
    this._velocityCaste,
    this._preferredVelocityCaste,
    this._circleColliderCaste, {
    double timeHorizon = 2.0,
    double maxSpeed = 100.0,
    double neighborDist = 150.0,
    int maxEntities = 65536,
  })  : _timeHorizon = timeHorizon,
        _maxSpeed = maxSpeed,
        _neighborDist = neighborDist,
        _newVelocities = Float32List(maxEntities * 2);

  /// Updates velocities based on RVO algorithm.
  void update(double dt) {
    final query = Query1<Position>(_positionCaste);

    // First pass: calculate new velocities for each agent
    query.forEach((entityA, posA) {
      final velA = _velocityCaste.get(entityA);
      final prefVelA = _preferredVelocityCaste.get(entityA);
      final circleA = _circleColliderCaste.get(entityA);

      if (velA == null || prefVelA == null || circleA == null) return;

      double newVx = prefVelA.dx;
      double newVy = prefVelA.dy;

      int penaltyCount = 0;
      double penaltyVx = 0.0;
      double penaltyVy = 0.0;

      // Defensively grow buffer if needed
      if (entityA * 2 >= _newVelocities.length) {
          final newLen = (entityA + 1024) * 2;
          final newBuf = Float32List(newLen);
          newBuf.setRange(0, _newVelocities.length, _newVelocities);
          _newVelocities = newBuf;
      }

      _grid.queryAABB(
        posA.x - _neighborDist,
        posA.y - _neighborDist,
        _neighborDist * 2,
        _neighborDist * 2,
        (entityB) {
          if (entityA == entityB) return true;

          final posB = _positionCaste.get(entityB);
          final velB = _velocityCaste.get(entityB);
          final circleB = _circleColliderCaste.get(entityB);

          if (posB == null || velB == null || circleB == null) return true;

          // Vector from A to B
          final double dx = posB.x - posA.x;
          final double dy = posB.y - posA.y;
          final double distSq = dx * dx + dy * dy;

          // Only consider neighbors within distance
          if (distSq > _neighborDist * _neighborDist) return true;

          final double dist = sqrt(distSq);

          // Combined radius
          final double radius = circleA.radius + circleB.radius;

          // Reciprocal relative velocity: 2*v - (v_A + v_B)
          // Relative velocity of A to B
          final double relVx = velA.dx - velB.dx;
          final double relVy = velA.dy - velB.dy;

          // Time to collision
          final double relDistSq = relVx * relVx + relVy * relVy;

          // If relative velocity is 0, no collision
          if (relDistSq < 0.0001) return true;

          final double relDist = sqrt(relDistSq);

          // Dot product of relative velocity and relative position
          final double dot = (relVx * dx + relVy * dy) / (relDist * dist);

          // If agents are moving apart, no collision
          if (dot <= 0) return true;

          // Project relative position onto relative velocity to find time to CPA (Closest Point of Approach)
          final double timeToCPA = dist * dot / relDist;

          // Calculate distance at CPA
          // cpaDist = dist * sin(theta), so cpaDistSq = distSq - (dist * dot)^2
          final double distDotSq = (dist * dot) * (dist * dot);
          final double cpaDistSq = distSq - distDotSq;

          // If distance at CPA is greater than combined radii, they won't collide
          if (cpaDistSq > radius * radius) return true;

          // Cross product of relative velocity and relative position
          // Right hand rule: positive means B is on the right, negative means B is on the left
          final double cross = relVx * dy - relVy * dx;

          // Add penalty if time to collision is within horizon
          if (timeToCPA < _timeHorizon) {
            final double weight = 1.0 - (timeToCPA / _timeHorizon);

            // Repulsion vector direction (orthogonal to relative velocity)
            // Right-hand passing bias: always prefer passing on the right (turning left is steering away)
            double repDirX, repDirY;
            if (cross >= 0) { // B is on the right, turn left
                repDirX = -relVy / relDist;
                repDirY = relVx / relDist;
            } else { // B is on the left, turn right
                repDirX = relVy / relDist;
                repDirY = -relVx / relDist;
            }

            penaltyVx += repDirX * weight * _maxSpeed;
            penaltyVy += repDirY * weight * _maxSpeed;
            penaltyCount++;
          }

          return true;
        }
      );

      if (penaltyCount > 0) {
        newVx += penaltyVx / penaltyCount;
        newVy += penaltyVy / penaltyCount;
      }

      // Limit speed
      final double speedSq = newVx * newVx + newVy * newVy;
      if (speedSq > _maxSpeed * _maxSpeed) {
        final double speed = sqrt(speedSq);
        newVx = (newVx / speed) * _maxSpeed;
        newVy = (newVy / speed) * _maxSpeed;
      }

      // Store new velocities
      _newVelocities[entityA * 2] = newVx;
      _newVelocities[entityA * 2 + 1] = newVy;
    });

    // Second pass: apply new velocities simultaneously
    query.forEach((entityA, posA) {
      final velA = _velocityCaste.get(entityA);
      final prefVelA = _preferredVelocityCaste.get(entityA);
      final circleA = _circleColliderCaste.get(entityA);

      if (velA == null || prefVelA == null || circleA == null) return;

      velA.dx = _newVelocities[entityA * 2];
      velA.dy = _newVelocities[entityA * 2 + 1];
    });
  }
}
