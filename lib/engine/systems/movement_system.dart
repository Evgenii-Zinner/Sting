import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';

/// A system that updates entities' Positions based on their Velocities and delta time.
class MovementSystem {
  final Query2<Position, Velocity> query;

  /// Creates a MovementSystem querying entities with both Position and Velocity.
  MovementSystem({
    required ComponentCaste<Position> positionCaste,
    required ComponentCaste<Velocity> velocityCaste,
  }) : query = Query2<Position, Velocity>(positionCaste, velocityCaste);

  /// Updates the position of all applicable entities.
  /// Modifies the Float32Lists directly without allocating new objects.
  void update(double dt) {
    query.forEach((entity, position, velocity) {
      double tempX = position.x;
      double tempY = position.y;

      position.x += velocity.dx * dt;
      position.y += velocity.dy * dt;

      position.prevX = tempX;
      position.prevY = tempY;
    });
  }
}
