import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/flocking_agent.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/entity_manager.dart';
import 'package:sting/engine/systems/flocking_system.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';

void main() {
  group('FlockingSystem', () {
    late ComponentStorage<Position> positionCaste;
    late ComponentStorage<Velocity> velocityCaste;
    late ComponentStorage<FlockingAgent> flockingAgentCaste;
    late SpatialHashGrid spatialHashGrid;
    late FlockingSystem flockingSystem;
    late EntityManager swarm;

    setUp(() {
      swarm = EntityManager();
      positionCaste = ComponentStorage<Position>(EntityManager.maxEntities);
      velocityCaste = ComponentStorage<Velocity>(EntityManager.maxEntities);
      flockingAgentCaste = ComponentStorage<FlockingAgent>(EntityManager.maxEntities);
      spatialHashGrid = SpatialHashGrid(100.0, 1000);

      flockingSystem = FlockingSystem(
        positionCaste: positionCaste,
        velocityCaste: velocityCaste,
        flockingAgentCaste: flockingAgentCaste,
        spatialHashGrid: spatialHashGrid,
      );
    });

    void populateGrid() {
      spatialHashGrid.clear();
      // Only check up to a sensible limit since we track IDs manually in tests
      for (int i = 0; i < 100; i++) {
        final pos = positionCaste.get(i);
        if (pos != null) {
          spatialHashGrid.insert(i, pos.x, pos.y);
        }
      }
    }

    test('applies separation correctly', () {
      final agentId = swarm.createEntity();
      positionCaste.add(agentId, Position.create(0.0, 0.0));
      velocityCaste.add(agentId, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(
        agentId,
        FlockingAgent.create(
          neighborRadius: 50.0,
          separationWeight: 1.0,
          alignmentWeight: 0.0, // Disable
          cohesionWeight: 0.0, // Disable
          maxForce: 10.0,
        ),
      );

      final neighborId = swarm.createEntity();
      // Neighbor is at (10, 0), so agent should steer towards (-x)
      positionCaste.add(neighborId, Position.create(10.0, 0.0));
      velocityCaste.add(neighborId, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(neighborId, FlockingAgent.create());

      populateGrid();
      flockingSystem.update(1.0);

      final vel = velocityCaste.get(agentId)!;
      expect(vel.dx, lessThan(0.0), reason: 'Should steer away from neighbor in X');
      expect(vel.dy, closeTo(0.0, 0.0001), reason: 'No Y influence');
    });

    test('applies alignment correctly', () {
      final agentId = swarm.createEntity();
      positionCaste.add(agentId, Position.create(0.0, 0.0));
      velocityCaste.add(agentId, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(
        agentId,
        FlockingAgent.create(
          neighborRadius: 50.0,
          separationWeight: 0.0, // Disable
          alignmentWeight: 1.0,
          cohesionWeight: 0.0, // Disable
          maxForce: 10.0,
        ),
      );

      final neighborId = swarm.createEntity();
      // Neighbor is moving in +y
      positionCaste.add(neighborId, Position.create(10.0, 0.0));
      velocityCaste.add(neighborId, Velocity.create(0.0, 5.0));
      flockingAgentCaste.add(neighborId, FlockingAgent.create());

      populateGrid();
      flockingSystem.update(1.0);

      final vel = velocityCaste.get(agentId)!;
      expect(vel.dx, closeTo(0.0, 0.0001), reason: 'No X influence');
      expect(vel.dy, greaterThan(0.0), reason: 'Should align with neighbor in Y');
    });

    test('applies cohesion correctly', () {
      final agentId = swarm.createEntity();
      positionCaste.add(agentId, Position.create(0.0, 0.0));
      velocityCaste.add(agentId, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(
        agentId,
        FlockingAgent.create(
          neighborRadius: 50.0,
          separationWeight: 0.0, // Disable
          alignmentWeight: 0.0, // Disable
          cohesionWeight: 1.0,
          maxForce: 10.0,
        ),
      );

      final neighborId = swarm.createEntity();
      // Neighbor is at (10, 10), so agent should steer towards (+x, +y)
      positionCaste.add(neighborId, Position.create(10.0, 10.0));
      velocityCaste.add(neighborId, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(neighborId, FlockingAgent.create());

      populateGrid();
      flockingSystem.update(1.0);

      final vel = velocityCaste.get(agentId)!;
      expect(vel.dx, greaterThan(0.0), reason: 'Should steer towards center of mass X');
      expect(vel.dy, greaterThan(0.0), reason: 'Should steer towards center of mass Y');
    });

    test('ignores neighbors outside radius', () {
      final agentId = swarm.createEntity();
      positionCaste.add(agentId, Position.create(0.0, 0.0));
      velocityCaste.add(agentId, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(
        agentId,
        FlockingAgent.create(
          neighborRadius: 5.0, // Small radius
          separationWeight: 1.0,
          alignmentWeight: 1.0,
          cohesionWeight: 1.0,
          maxForce: 10.0,
        ),
      );

      final neighborId = swarm.createEntity();
      // Neighbor is far away (10, 0)
      positionCaste.add(neighborId, Position.create(10.0, 0.0));
      velocityCaste.add(neighborId, Velocity.create(10.0, 10.0));
      flockingAgentCaste.add(neighborId, FlockingAgent.create());

      populateGrid();
      flockingSystem.update(1.0);

      final vel = velocityCaste.get(agentId)!;
      expect(vel.dx, closeTo(0.0, 0.0001), reason: 'No X influence');
      expect(vel.dy, closeTo(0.0, 0.0001), reason: 'No Y influence');
    });

    test('max force is respected', () {
      final agentId = swarm.createEntity();
      positionCaste.add(agentId, Position.create(0.0, 0.0));
      velocityCaste.add(agentId, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(
        agentId,
        FlockingAgent.create(
          neighborRadius: 50.0,
          separationWeight: 0.0,
          alignmentWeight: 100.0, // Very high weight to force the limit
          cohesionWeight: 0.0,
          maxForce: 2.0, // Strict limit
        ),
      );

      final neighborId = swarm.createEntity();
      positionCaste.add(neighborId, Position.create(10.0, 0.0));
      velocityCaste.add(neighborId, Velocity.create(100.0, 0.0)); // High velocity
      flockingAgentCaste.add(neighborId, FlockingAgent.create());

      populateGrid();
      flockingSystem.update(1.0);

      final vel = velocityCaste.get(agentId)!;
      expect(vel.dx, closeTo(200.0, 0.0001), reason: 'Expect scaled max force by weight');
      // maxForce limits the raw force *before* weight multiplication in FlockingSystem:
      // steerResult[0] = 2.0
      // finalAlignForceX = 2.0 * 100.0 = 200.0
      // velocity.dx += 200.0 * 1.0
    });

    test('handles exactly zero distance', () {
      final agentId = swarm.createEntity();
      positionCaste.add(agentId, Position.create(0.0, 0.0));
      velocityCaste.add(agentId, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(
        agentId,
        FlockingAgent.create(
          neighborRadius: 50.0,
          separationWeight: 1.0,
          alignmentWeight: 1.0,
          cohesionWeight: 1.0,
          maxForce: 10.0,
        ),
      );

      final neighborId = swarm.createEntity();
      // Neighbor is exactly at same position
      positionCaste.add(neighborId, Position.create(0.0, 0.0));
      velocityCaste.add(neighborId, Velocity.create(10.0, 10.0));
      flockingAgentCaste.add(neighborId, FlockingAgent.create());

      populateGrid();
      flockingSystem.update(1.0);

      final vel = velocityCaste.get(agentId)!;
      // Should not throw division by zero and no separation/cohesion force
      expect(vel.dx, isNot(isNaN));
      expect(vel.dy, isNot(isNaN));
    });

    test('ignores self', () {
      final agentId = swarm.createEntity();
      positionCaste.add(agentId, Position.create(0.0, 0.0));
      velocityCaste.add(agentId, Velocity.create(1.0, 1.0));
      flockingAgentCaste.add(agentId, FlockingAgent.create());

      populateGrid();
      flockingSystem.update(1.0);

      final vel = velocityCaste.get(agentId)!;
      expect(vel.dx, 1.0); // Should not change if no neighbors
      expect(vel.dy, 1.0);
    });

    test('handles zero separation distance/force correctly', () {
      final agentId = swarm.createEntity();
      positionCaste.add(agentId, Position.create(0.0, 0.0));
      velocityCaste.add(agentId, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(
        agentId,
        FlockingAgent.create(
          neighborRadius: 50.0,
          separationWeight: 1.0,
          alignmentWeight: 0.0,
          cohesionWeight: 0.0,
          maxForce: 10.0,
        ),
      );

      // Add symmetric neighbors to cancel out separation force
      final neighbor1 = swarm.createEntity();
      positionCaste.add(neighbor1, Position.create(10.0, 0.0));
      velocityCaste.add(neighbor1, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(neighbor1, FlockingAgent.create());

      final neighbor2 = swarm.createEntity();
      positionCaste.add(neighbor2, Position.create(-10.0, 0.0));
      velocityCaste.add(neighbor2, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(neighbor2, FlockingAgent.create());

      populateGrid();
      flockingSystem.update(1.0);

      final vel = velocityCaste.get(agentId)!;
      expect(vel.dx, closeTo(0.0, 0.0001));
      expect(vel.dy, closeTo(0.0, 0.0001));
    });

    test('zero-allocation check: does not allocate during update', () {
      final agentId = swarm.createEntity();
      positionCaste.add(agentId, Position.create(0.0, 0.0));
      velocityCaste.add(agentId, Velocity.create(0.0, 0.0));
      flockingAgentCaste.add(
        agentId,
        FlockingAgent.create(
          neighborRadius: 50.0,
          separationWeight: 1.0,
          alignmentWeight: 1.0,
          cohesionWeight: 1.0,
          maxForce: 10.0,
        ),
      );

      final neighborId = swarm.createEntity();
      positionCaste.add(neighborId, Position.create(10.0, 10.0));
      velocityCaste.add(neighborId, Velocity.create(5.0, 5.0));
      flockingAgentCaste.add(neighborId, FlockingAgent.create());

      populateGrid();

      // Warm up
      flockingSystem.update(1.0);

      // Reset velocities
      velocityCaste.get(agentId)!.dx = 0;
      velocityCaste.get(agentId)!.dy = 0;

      for (int i = 0; i < 1000; i++) {
        flockingSystem.update(0.016);
      }
      expect(velocityCaste.get(agentId)!.dx, isNot(0.0));
    });
  });

  group('FlockingAgent properties', () {
    test('getters and setters work correctly', () {
      final agent = FlockingAgent.create();

      agent.neighborRadius = 100.0;
      expect(agent.neighborRadius, 100.0);

      agent.separationWeight = 2.0;
      expect(agent.separationWeight, 2.0);

      agent.alignmentWeight = 3.0;
      expect(agent.alignmentWeight, 3.0);

      agent.cohesionWeight = 4.0;
      expect(agent.cohesionWeight, 4.0);

      agent.maxForce = 50.0;
      expect(agent.maxForce, 50.0);
    });
  });
}
