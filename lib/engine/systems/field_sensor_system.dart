import 'package:sting/engine/components/field_sensor.dart';
import 'package:sting/engine/components/ground_trail_field.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/preferred_velocity.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';

/// A system that evaluates scalar fields at entity positions and applies proportional steering forces.
/// Zero per-frame allocations.
class FieldSensorSystem {
  final ComponentStorage<GroundTrailField> fieldCaste;

  final Query3<Position, FieldSensor, Velocity> _velQuery;
  final Query3<Position, FieldSensor, PreferredVelocity> _prefVelQuery;

  double _currentDt = 0.0;

  /// Creates a FieldSensorSystem.
  FieldSensorSystem({
    required ComponentStorage<Position> positionCaste,
    required ComponentStorage<FieldSensor> sensorCaste,
    required ComponentStorage<Velocity> velocityCaste,
    required ComponentStorage<PreferredVelocity> preferredVelocityCaste,
    required this.fieldCaste,
  })  : _velQuery = Query3<Position, FieldSensor, Velocity>(
          positionCaste,
          sensorCaste,
          velocityCaste,
        ),
        _prefVelQuery = Query3<Position, FieldSensor, PreferredVelocity>(
          positionCaste,
          sensorCaste,
          preferredVelocityCaste,
        );

  /// Updates the sensors, calculating gradients and applying steering forces.
  void update(double dt) {
    if (dt <= 0.0) return;
    _currentDt = dt;
    _velQuery.forEach(_processVelocity);
    _prefVelQuery.forEach(_processPreferredVelocity);
  }

  void _processVelocity(int entity, Position pos, FieldSensor sensor, Velocity vel) {
    final field = fieldCaste.get(sensor.targetChannel);
    if (field == null) return;

    final double r = sensor.sensorRadius;
    if (r <= 0.0) return;

    final double valCenter = field.sampleValue(pos.x, pos.y);
    sensor.lastSampledValue = valCenter;

    final double valRight = field.sampleValue(pos.x + r, pos.y);
    final double valLeft = field.sampleValue(pos.x - r, pos.y);
    final double valDown = field.sampleValue(pos.x, pos.y + r);
    final double valUp = field.sampleValue(pos.x, pos.y - r);

    final double gx = (valRight - valLeft) / (2.0 * r);
    final double gy = (valDown - valUp) / (2.0 * r);

    sensor.lastGradientX = gx;
    sensor.lastGradientY = gy;

    final double sens = sensor.sensitivity;
    vel.dx += gx * sens * _currentDt;
    vel.dy += gy * sens * _currentDt;
  }

  void _processPreferredVelocity(int entity, Position pos, FieldSensor sensor, PreferredVelocity prefVel) {
    final field = fieldCaste.get(sensor.targetChannel);
    if (field == null) return;

    final double r = sensor.sensorRadius;
    if (r <= 0.0) return;

    final double valCenter = field.sampleValue(pos.x, pos.y);
    sensor.lastSampledValue = valCenter;

    final double valRight = field.sampleValue(pos.x + r, pos.y);
    final double valLeft = field.sampleValue(pos.x - r, pos.y);
    final double valDown = field.sampleValue(pos.x, pos.y + r);
    final double valUp = field.sampleValue(pos.x, pos.y - r);

    final double gx = (valRight - valLeft) / (2.0 * r);
    final double gy = (valDown - valUp) / (2.0 * r);

    sensor.lastGradientX = gx;
    sensor.lastGradientY = gy;

    final double sens = sensor.sensitivity;
    prefVel.dx += gx * sens * _currentDt;
    prefVel.dy += gy * sens * _currentDt;
  }
}
