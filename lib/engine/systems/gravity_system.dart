import 'dart:typed_data';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/mass.dart';
import 'package:sting/engine/math/quadtree.dart';
import 'package:sting/engine/systems/game_state_system.dart';

/// A system that calculates and applies gravitational forces using a Barnes-Hut Quadtree.
class GravitySystem {
  final BarnesHutTree _tree;
  final GameStateSystem _gameStateSystem;

  // Configuration
  final double theta;
  final double g;

  // Reusable force array
  final Float32List _forceBuffer = Float32List(2);

  GravitySystem(this._gameStateSystem,
      {this.theta = 0.5, this.g = 1.0, int maxNodes = 40000})
      : _tree = BarnesHutTree(maxNodes: maxNodes);

  /// Updates all entities with Position, Velocity, and Mass.
  void update(Scene scene, double dt) {
    if (!_gameStateSystem.shouldUpdateLogic()) return;

    final positions = scene.getCaste<Position>('Position');
    final velocities = scene.getCaste<Velocity>('Velocity');
    final masses = scene.getCaste<Mass>('Mass');

    // 1. Find bounds for the quadtree
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    // We only iterate entities that have ALL three components
    // We'll iterate the smallest caste, typically Mass.
    if (masses.length == 0) return;

    for (int i = 0; i < masses.length; i++) {
      int entity = masses.elementAt(i);
      final pos = positions.get(entity);
      if (pos == null) continue;
      final vel = velocities.get(entity);
      if (vel == null) continue;

      if (pos.x < minX) minX = pos.x;
      if (pos.x > maxX) maxX = pos.x;
      if (pos.y < minY) minY = pos.y;
      if (pos.y > maxY) maxY = pos.y;
    }

    if (minX == double.infinity) return;

    // Make bounds square and slightly larger to prevent boundary issues
    double width = maxX - minX;
    double height = maxY - minY;
    double size = width > height ? width : height;

    // Add small padding
    size += 1.0;
    minX -= 0.5;
    minY -= 0.5;

    // 2. Initialize and populate tree
    _tree.initRoot(minX, minY, size, size);

    for (int i = 0; i < masses.length; i++) {
      int entity = masses.elementAt(i);
      final pos = positions.get(entity);
      if (pos == null) continue;
      final vel = velocities.get(entity);
      if (vel == null) continue;

      final mass = masses.getComponentAt(i)!;

      _tree.insert(entity, pos.x, pos.y, mass.value);
    }

    // 3. Calculate forces and update velocities
    for (int i = 0; i < masses.length; i++) {
      int entity = masses.elementAt(i);
      final pos = positions.get(entity);
      if (pos == null) continue;
      final vel = velocities.get(entity);
      if (vel == null) continue;

      // Initialize Verlet history for newly spawned entities using their starting velocity
      if (pos.prevX == pos.x &&
          pos.prevY == pos.y &&
          (vel.dx != 0.0 || vel.dy != 0.0)) {
        pos.prevX = pos.x - vel.dx * dt;
        pos.prevY = pos.y - vel.dy * dt;
      }

      _forceBuffer[0] = 0.0;
      _forceBuffer[1] = 0.0;

      _tree.accumulateForce(entity, pos.x, pos.y, theta, g, _forceBuffer);

      // Verlet Integration Step (much more stable for orbits)
      final double tempX = pos.x;
      final double tempY = pos.y;

      final double accX = _forceBuffer[0];
      final double accY = _forceBuffer[1];

      pos.x = 2.0 * pos.x - pos.prevX + accX * dt * dt;
      pos.y = 2.0 * pos.y - pos.prevY + accY * dt * dt;

      pos.prevX = tempX;
      pos.prevY = tempY;

      // Keep velocity component in sync for other subsystems
      if (dt > 0.0) {
        vel.dx = (pos.x - pos.prevX) / dt;
        vel.dy = (pos.y - pos.prevY) / dt;
      }
    }
  }
}
