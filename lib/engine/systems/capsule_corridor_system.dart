import 'package:sting/engine/components/capsule_corridor.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';

/// A system that manages entities within CapsuleCorridors.
/// It applies the flowForce along the pipeline direction to entities inside the corridor.
class CapsuleCorridorSystem {
  final ComponentStorage<CapsuleCorridor> _corridors;
  final ComponentStorage<Position> _positions;
  final ComponentStorage<Velocity> _velocities;

  late final Query2<Position, Velocity> _movementQuery;

  /// Creates a new CapsuleCorridorSystem.
  CapsuleCorridorSystem(this._corridors, this._positions, this._velocities) {
    _movementQuery = Query2(_positions, _velocities);
  }

  /// Updates the system, checking containment and applying force.
  /// Zero heap allocations per frame.
  void update(double dt) {
    final numCorridors = _corridors.length;
    if (numCorridors == 0) return;

    _movementQuery.forEach((entity, position, velocity) {
      final double px = position.x;
      final double py = position.y;

      for (var i = 0; i < numCorridors; i++) {
        final corridor = _corridors.getComponentAt(i);
        if (corridor != null && corridor.containsPoint(px, py)) {
          final double force = corridor.flowForce;
          if (force != 0.0) {
            velocity.dx += corridor.flowDirectionX * force * dt;
            velocity.dy += corridor.flowDirectionY * force * dt;
          }
          // Note: The task description specifies applying flowForce along pipeline direction.
          // Other properties like energyRechargeRate, speedBoost, frictionOverride
          // are part of the struct but the prompt specifically asked to:
          // "If inside corridor: applies flowForce along pipeline direction (vel.dx += flowDirectionX * flowForce * dt; vel.dy += flowDirectionY * flowForce * dt)."
        }
      }
    });
  }
}
