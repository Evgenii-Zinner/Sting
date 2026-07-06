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

      _forceBuffer[0] = 0.0;
      _forceBuffer[1] = 0.0;

      _tree.accumulateForce(entity, pos.x, pos.y, theta, g, _forceBuffer);

      // dv = (F/m) * dt, but actually the tree returns acceleration (since we didn't multiply by receiving body mass inside tree)
      // Wait, tree force formula: F = G * M / d^2.
      // If we want true force: F_total = G * M * m / d^2.
      // We did: force = (g * mass) / distSq. This is actually acceleration if it's the source mass!
      // Acceleration a = F/m = (G * M * m / d^2) / m = G * M / d^2.
      // Yes! _tree.accumulateForce returns ACCELERATION!

      vel.dx += _forceBuffer[0] * dt;
      vel.dy += _forceBuffer[1] * dt;
    }
  }
}
