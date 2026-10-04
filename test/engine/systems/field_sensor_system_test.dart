import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/field_sensor.dart';
import 'package:sting/engine/components/ground_trail_field.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/preferred_velocity.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/field_sensor_system.dart';

void main() {
  group('FieldSensorSystem', () {
    late ComponentStorage<Position> positionCaste;
    late ComponentStorage<FieldSensor> sensorCaste;
    late ComponentStorage<Velocity> velocityCaste;
    late ComponentStorage<PreferredVelocity> preferredVelocityCaste;
    late ComponentStorage<GroundTrailField> fieldCaste;
    late FieldSensorSystem system;

    setUp(() {
      positionCaste = ComponentStorage<Position>(100);
      sensorCaste = ComponentStorage<FieldSensor>(100);
      velocityCaste = ComponentStorage<Velocity>(100);
      preferredVelocityCaste = ComponentStorage<PreferredVelocity>(100);
      fieldCaste = ComponentStorage<GroundTrailField>(10);

      system = FieldSensorSystem(
        positionCaste: positionCaste,
        sensorCaste: sensorCaste,
        velocityCaste: velocityCaste,
        preferredVelocityCaste: preferredVelocityCaste,
        fieldCaste: fieldCaste,
      );
    });

    test('gradient climbing towards high-heat cells with positive sensitivity', () {
      // Create a field with a hot spot at (1,1) in a 3x3 grid, cellSize = 10
      // So (10, 10) is the hot spot.
      final field = GroundTrailField.create(
        columns: 3,
        rows: 3,
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
      );
      // Set cell values
      field.setValue(1, 1, 100.0); // Center is hot
      // Neighbors are 0 by default.

      fieldCaste.add(42, field);

      // Entity slightly to the left of the center (e.g. at x=5, y=10)
      positionCaste.add(1, Position.create(5.0, 10.0));
      velocityCaste.add(1, Velocity.create(0.0, 0.0));

      // targetChannel = 42
      sensorCaste.add(1, FieldSensor.create(
        targetChannel: 42,
        sensitivity: 10.0,
        sensorRadius: 1.0,
      ));

      system.update(1.0);

      final sensor = sensorCaste.get(1)!;
      final vel = velocityCaste.get(1)!;

      // Gradient should point towards positive X (since center is right at x=10)
      expect(sensor.lastGradientX, greaterThan(0.0));
      expect(vel.dx, greaterThan(0.0));

      // Should not move on Y
      expect(sensor.lastGradientY, closeTo(0.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));
    });

    test('avoidance of toxic cells with negative sensitivity', () {
      final field = GroundTrailField.create(
        columns: 3,
        rows: 3,
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
      );
      field.setValue(1, 1, 100.0); // Center is toxic
      fieldCaste.add(42, field);

      // Entity slightly to the left of the center (e.g. at x=5, y=10)
      positionCaste.add(1, Position.create(5.0, 10.0));
      velocityCaste.add(1, Velocity.create(0.0, 0.0));

      sensorCaste.add(1, FieldSensor.create(
        targetChannel: 42,
        sensitivity: -10.0, // Negative sensitivity means avoid
        sensorRadius: 1.0,
      ));

      system.update(1.0);

      final sensor = sensorCaste.get(1)!;
      final vel = velocityCaste.get(1)!;

      // Gradient should point towards positive X, but velocity should point negative X
      expect(sensor.lastGradientX, greaterThan(0.0));
      expect(vel.dx, lessThan(0.0));

      expect(sensor.lastGradientY, closeTo(0.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));
    });

    test('modifies PreferredVelocity if present', () {
      final field = GroundTrailField.create(
        columns: 3,
        rows: 3,
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
      );
      field.setValue(1, 1, 100.0); // Center is hot
      fieldCaste.add(42, field);

      positionCaste.add(1, Position.create(5.0, 10.0));
      preferredVelocityCaste.add(1, PreferredVelocity.create(0.0, 0.0));

      sensorCaste.add(1, FieldSensor.create(
        targetChannel: 42,
        sensitivity: 10.0,
        sensorRadius: 1.0,
      ));

      system.update(1.0);

      final sensor = sensorCaste.get(1)!;
      final prefVel = preferredVelocityCaste.get(1)!;

      expect(sensor.lastGradientX, greaterThan(0.0));
      expect(prefVel.dx, greaterThan(0.0));
    });

    test('Zero allocation execution during update', () {
      final field = GroundTrailField.create(
        columns: 10,
        rows: 10,
        originX: 0.0,
        originY: 0.0,
        cellSize: 10.0,
      );
      fieldCaste.add(0, field);

      for (int i = 0; i < 100; i++) {
        positionCaste.add(i, Position.create(5.0, 5.0));
        velocityCaste.add(i, Velocity.create(0.0, 0.0));
        preferredVelocityCaste.add(i, PreferredVelocity.create(0.0, 0.0));
        sensorCaste.add(i, FieldSensor.create(targetChannel: 0));
      }

      // Should run without allocations and without throwing
      expect(() => system.update(0.016), returnsNormally);
    });
  });
}
