import 'dart:math';

import 'package:sting/engine/components/flocking_agent.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';

/// A system that calculates and applies Reynolds' flocking behavior to agents.
/// It uses a [SpatialHashGrid] for O(N) neighbor queries and processes forces
/// with zero allocations.
class FlockingSystem {
  final Query3<Position, Velocity, FlockingAgent> query;
  final SpatialHashGrid spatialHashGrid;

  // Reused components for queries to avoid allocating captured variables
  final ComponentCaste<Position> _positionCaste;
  final ComponentCaste<Velocity> _velocityCaste;

  // Temporary state for the current agent being queried
  int _currentAgentId = -1;
  double _currentAgentX = 0.0;
  double _currentAgentY = 0.0;
  double _neighborRadiusSq = 0.0;

  // Accumulators for forces
  double _sepForceX = 0.0;
  double _sepForceY = 0.0;
  double _alignVelX = 0.0;
  double _alignVelY = 0.0;
  double _cohCenterX = 0.0;
  double _cohCenterY = 0.0;
  int _neighborCount = 0;

  /// Creates a FlockingSystem querying entities with Position, Velocity, and FlockingAgent.
  FlockingSystem({
    required ComponentCaste<Position> positionCaste,
    required ComponentCaste<Velocity> velocityCaste,
    required ComponentCaste<FlockingAgent> flockingAgentCaste,
    required this.spatialHashGrid,
  })  : _positionCaste = positionCaste,
        _velocityCaste = velocityCaste,
        query = Query3<Position, Velocity, FlockingAgent>(
            positionCaste, velocityCaste, flockingAgentCaste);

  /// Helper to calculate the forces inside the query closure without allocation
  bool _processNeighbor(int neighborId) {
    if (neighborId == _currentAgentId) {
      return true;
    }

    final neighborPos = _positionCaste.get(neighborId);
    final neighborVel = _velocityCaste.get(neighborId);

    if (neighborPos != null && neighborVel != null) {
      final double dx = _currentAgentX - neighborPos.x;
      final double dy = _currentAgentY - neighborPos.y;
      final double distSq = dx * dx + dy * dy;

      if (distSq > 0.0 && distSq < _neighborRadiusSq) {
        final double dist = sqrt(distSq);

        // Separation
        final double sepScale = 1.0 / dist; // Weight by distance
        _sepForceX += (dx / dist) * sepScale;
        _sepForceY += (dy / dist) * sepScale;

        // Alignment
        _alignVelX += neighborVel.dx;
        _alignVelY += neighborVel.dy;

        // Cohesion
        _cohCenterX += neighborPos.x;
        _cohCenterY += neighborPos.y;

        _neighborCount++;
      }
    }

    return true; // continue query
  }

  /// Limits a vector to a maximum length.
  void _limitForce(List<double> force, double maxForce) {
    final double distSq = force[0] * force[0] + force[1] * force[1];
    if (distSq > maxForce * maxForce && distSq > 0.000001) {
      final double dist = sqrt(distSq);
      force[0] = (force[0] / dist) * maxForce;
      force[1] = (force[1] / dist) * maxForce;
    }
  }

  // Reusable array to prevent per-frame allocations when limiting forces
  final List<double> _steerResult = [0.0, 0.0];

  /// Updates velocities of all applicable flocking agents based on separation, alignment, and cohesion.
  void update(double dt) {
    // We assume the spatialHashGrid has already been populated with agent positions.
    // In Sting, a separate system or main loop usually clears and populates the grid.

    query.forEach((entity, position, velocity, agent) {
      _currentAgentId = entity;
      _currentAgentX = position.x;
      _currentAgentY = position.y;
      _neighborRadiusSq = agent.neighborRadius * agent.neighborRadius;

      _sepForceX = 0.0;
      _sepForceY = 0.0;
      _alignVelX = 0.0;
      _alignVelY = 0.0;
      _cohCenterX = 0.0;
      _cohCenterY = 0.0;
      _neighborCount = 0;

      // Query local neighbors
      spatialHashGrid.queryAABB(
        position.x - agent.neighborRadius,
        position.y - agent.neighborRadius,
        agent.neighborRadius * 2.0,
        agent.neighborRadius * 2.0,
        _processNeighbor,
      );

      if (_neighborCount > 0) {
        // Average the accumulated forces
        final double invCount = 1.0 / _neighborCount;

        // Separation force
        // Has no specific "desired velocity" since we just push away, but we apply max force scaling.
        _steerResult[0] = _sepForceX;
        _steerResult[1] = _sepForceY;
        if (_steerResult[0] * _steerResult[0] + _steerResult[1] * _steerResult[1] > 0.000001) {
             final double sDistSq = _steerResult[0] * _steerResult[0] + _steerResult[1] * _steerResult[1];
             final double sDist = sqrt(sDistSq);
             // Normalize and scale to max force limit (or some logic; we'll treat the average as the force directly but bound it)
             _steerResult[0] = (_steerResult[0] / sDist) * agent.maxForce; // Simplification of Reynolds' sep
             _steerResult[1] = (_steerResult[1] / sDist) * agent.maxForce;
        } else {
             _steerResult[0] = 0.0;
             _steerResult[1] = 0.0;
        }

        final double finalSepForceX = _steerResult[0] * agent.separationWeight;
        final double finalSepForceY = _steerResult[1] * agent.separationWeight;


        // Alignment force
        // steer = desired - velocity
        _alignVelX *= invCount;
        _alignVelY *= invCount;

        _steerResult[0] = _alignVelX - velocity.dx;
        _steerResult[1] = _alignVelY - velocity.dy;
        _limitForce(_steerResult, agent.maxForce);

        final double finalAlignForceX = _steerResult[0] * agent.alignmentWeight;
        final double finalAlignForceY = _steerResult[1] * agent.alignmentWeight;


        // Cohesion force
        // steer = desired - velocity where desired = center - position
        _cohCenterX *= invCount;
        _cohCenterY *= invCount;

        double desiredCohX = _cohCenterX - position.x;
        double desiredCohY = _cohCenterY - position.y;
        final double cohDistSq = desiredCohX * desiredCohX + desiredCohY * desiredCohY;

        // We often normalize this desired velocity if dist > 0
        if (cohDistSq > 0.000001) {
            final double cohDist = sqrt(cohDistSq);
            // Some implementations scale to maxSpeed, here we just normalize then subtract current velocity
            // In standard boids we would scale to a max speed, but flocking agent doesn't have maxSpeed.
            // Wait, we need to guide it towards the center.
            // Let's use a simple steering force approach.
            desiredCohX /= cohDist;
            desiredCohY /= cohDist;
            // assume unit vector * arbitrary scale, or simply:
        }

        _steerResult[0] = desiredCohX - velocity.dx;
        _steerResult[1] = desiredCohY - velocity.dy;
        _limitForce(_steerResult, agent.maxForce);

        final double finalCohForceX = _steerResult[0] * agent.cohesionWeight;
        final double finalCohForceY = _steerResult[1] * agent.cohesionWeight;

        // Apply forces to velocity (v = v + a*dt)
        velocity.dx += (finalSepForceX + finalAlignForceX + finalCohForceX) * dt;
        velocity.dy += (finalSepForceY + finalAlignForceY + finalCohForceY) * dt;
      }
    });
  }
}
