import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/ground_trail_field.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/trail_emitter.dart';
import 'package:sting/engine/components/trail_feedback.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/ground_trail_system.dart';

void main() {
  group('GroundTrailSystem', () {
    late ComponentStorage<GroundTrailField> fieldCaste;
    late ComponentStorage<Position> positionCaste;
    late ComponentStorage<TrailEmitter> emitterCaste;
    late ComponentStorage<TrailFeedback> feedbackCaste;
    late GroundTrailSystem system;

    setUp(() {
      fieldCaste = ComponentStorage<GroundTrailField>(10);
      positionCaste = ComponentStorage<Position>(100);
      emitterCaste = ComponentStorage<TrailEmitter>(100);
      feedbackCaste = ComponentStorage<TrailFeedback>(100);

      system = GroundTrailSystem(
        fieldCaste: fieldCaste,
        positionCaste: positionCaste,
        emitterCaste: emitterCaste,
        feedbackCaste: feedbackCaste,
      );
    });

    test('field decay over time', () {
      final field = GroundTrailField.create(
        columns: 5,
        rows: 5,
        decayRate: 2.0,
      );
      fieldCaste.add(1, field);

      field.setValue(2, 2, 10.0);
      field.setValue(1, 1, 1.0);

      system.update(0.5); // decay = 2.0 * 0.5 = 1.0

      expect(field.getValue(2, 2), closeTo(9.0, 0.001));
      expect(field.getValue(1, 1), closeTo(0.0, 0.001)); // clamped to 0.0
    });

    test('trail deposition and accumulation from moving emitters', () {
      final field = GroundTrailField.create(
        columns: 10,
        rows: 10,
        cellSize: 10.0,
        decayRate: 0.0,
      );
      fieldCaste.add(1, field);

      final emitterEntity = 2;
      positionCaste.add(emitterEntity, Position.create(15.0, 15.0)); // Cell (1, 1)
      emitterCaste.add(emitterEntity, TrailEmitter.create(5.0)); // Add 5.0 per second

      system.update(1.0);
      expect(field.getValue(1, 1), closeTo(5.0, 0.001));

      // Move entity and update again
      positionCaste.get(emitterEntity)!.x = 25.0; // Cell (2, 1)
      system.update(2.0); // Adds 10.0
      expect(field.getValue(1, 1), closeTo(5.0, 0.001)); // Old cell unchanged
      expect(field.getValue(2, 1), closeTo(10.0, 0.001)); // New cell gets 10.0
    });

    test('feedback isOnTrail activation when threshold is reached', () {
      final field = GroundTrailField.create(
        columns: 10,
        rows: 10,
        cellSize: 10.0,
        decayRate: 0.0,
      );
      fieldCaste.add(1, field);

      field.setValue(3, 3, 20.0); // Ground value is 20.0 here
      field.setValue(4, 4, 10.0); // Ground value is 10.0 here

      final agentEntity = 3;
      positionCaste.add(agentEntity, Position.create(35.0, 35.0)); // Cell (3, 3)
      final feedback = TrailFeedback.create(
        baseFriction: 0.5,
        boostedFriction: 0.1,
        threshold: 15.0,
      );
      feedbackCaste.add(agentEntity, feedback);

      system.update(0.1);

      // Threshold 15.0, cell value 20.0 -> true
      expect(feedback.isOnTrail, isTrue);

      // Move to cell (4, 4) where value is 10.0
      positionCaste.get(agentEntity)!.x = 45.0;
      positionCaste.get(agentEntity)!.y = 45.0;

      system.update(0.1);

      // Threshold 15.0, cell value 10.0 -> false
      expect(feedback.isOnTrail, isFalse);
    });

    test('maxIntensity limits deposition', () {
      final field = GroundTrailField.create(
        columns: 2,
        rows: 2,
        cellSize: 10.0,
        maxIntensity: 50.0,
        decayRate: 0.0,
      );
      fieldCaste.add(1, field);
      field.setValue(0, 0, 48.0);

      final emitterEntity = 2;
      positionCaste.add(emitterEntity, Position.create(5.0, 5.0)); // Cell (0, 0)
      emitterCaste.add(emitterEntity, TrailEmitter.create(10.0));

      system.update(1.0);

      // 48.0 + 10.0 = 58.0 -> clamped to 50.0
      expect(field.getValue(0, 0), closeTo(50.0, 0.001));
    });

    test('sampleValue bilinearly interpolates correctly', () {
      final field = GroundTrailField.create(
        columns: 2,
        rows: 2,
        cellSize: 10.0,
        decayRate: 0.0,
      );

      field.setValue(0, 0, 10.0);
      field.setValue(1, 0, 20.0);
      field.setValue(0, 1, 30.0);
      field.setValue(1, 1, 40.0);

      expect(field.sampleValue(0.0, 0.0), closeTo(10.0, 0.001));
      expect(field.sampleValue(5.0, 0.0), closeTo(15.0, 0.001)); // midpoint horizontally
      expect(field.sampleValue(0.0, 5.0), closeTo(20.0, 0.001)); // midpoint vertically
      expect(field.sampleValue(5.0, 5.0), closeTo(25.0, 0.001)); // midpoint both
    });
  });
}
