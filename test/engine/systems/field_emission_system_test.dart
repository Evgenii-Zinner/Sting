import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/field_emitter.dart';
import 'package:sting/engine/components/ground_trail_field.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/field_emission_system.dart';

void main() {
  group('FieldEmissionSystem Tests', () {
    late ComponentStorage<Position> positions;
    late ComponentStorage<FieldEmitter> emitters;
    late GroundTrailField channel0;
    late GroundTrailField channel1;
    late Map<int, GroundTrailField> channels;
    late FieldEmissionSystem system;

    setUp(() {
      positions = ComponentStorage<Position>(10);
      emitters = ComponentStorage<FieldEmitter>(10);

      channel0 = GroundTrailField.create(
        columns: 10,
        rows: 10,
        cellSize: 10.0,
        originX: 0.0,
        originY: 0.0,
      );

      channel1 = GroundTrailField.create(
        columns: 10,
        rows: 10,
        cellSize: 10.0,
        originX: 0.0,
        originY: 0.0,
      );

      channels = {
        0: channel0,
        1: channel1,
      };

      system = FieldEmissionSystem(
        positionCaste: positions,
        emitterCaste: emitters,
        channels: channels,
      );
    });

    test('Inactive emitter does not splat', () {
      positions.add(1, Position.create(5.0, 5.0)); // Cell 0,0 center is 5,5
      emitters.add(
          1,
          FieldEmitter.create(
            targetChannel: 0,
            emissionRate: 10.0,
            radius: 5.0,
            falloffType: 2, // Flat
            isActive: false,
          ));

      system.update(1.0);

      expect(channel0.getValue(0, 0), 0.0);
    });

    test('Emitter without position does not splat', () {
      emitters.add(
          1,
          FieldEmitter.create(
            targetChannel: 0,
            emissionRate: 10.0,
            radius: 5.0,
            falloffType: 2, // Flat
            isActive: true,
          ));

      system.update(1.0);

      expect(channel0.getValue(0, 0), 0.0);
    });

    test('Flat falloff splats evenly within radius', () {
      positions.add(1, Position.create(15.0, 15.0)); // Cell 1,1
      emitters.add(
          1,
          FieldEmitter.create(
            targetChannel: 0,
            emissionRate: 10.0,
            radius: 12.0, // Should hit 1,1 heavily and reach neighbors
            falloffType: 2, // Flat
            isActive: true,
          ));

      system.update(0.5); // dt = 0.5, total = 5.0

      expect(channel0.getValue(1, 1), 5.0);
      expect(channel0.getValue(0, 1), 5.0);
      expect(channel0.getValue(2, 1), 5.0);
      expect(channel0.getValue(1, 0), 5.0);
      expect(channel0.getValue(1, 2), 5.0);
      // Diagonals are distance 14.14 from 15,15 to center of 0,0 (5,5) which is > 12.0
      // So 0,0 should be 0
      expect(channel0.getValue(0, 0), 0.0);
    });

    test('Bilinear falloff splats proportionally based on distance', () {
      // Cell 2,2 center is 25,25
      positions.add(1, Position.create(25.0, 25.0));
      emitters.add(
          1,
          FieldEmitter.create(
            targetChannel: 0,
            emissionRate: 20.0,
            radius: 20.0,
            falloffType: 0, // Bilinear
            isActive: true,
          ));

      system.update(1.0); // dt = 1.0, base = 20.0

      // Distance to 2,2 is 0. Factor = 1.0
      expect(channel0.getValue(2, 2), 20.0);

      // Distance to 1,2 (center 15,25) is 10. Factor = 1.0 - (10/20) = 0.5
      // 0.5 * 20.0 = 10.0
      expect(channel0.getValue(1, 2), 10.0);
      expect(channel0.getValue(3, 2), 10.0);

      // Distance to 1,1 (center 15,15) is 14.14. Factor = 1.0 - (14.14/20) = 0.2929
      // 0.2929 * 20.0 = 5.858
      expect(channel0.getValue(1, 1), closeTo(5.85, 0.01));
    });

    test('Gaussian falloff splats based on exp curve', () {
      positions.add(1, Position.create(25.0, 25.0)); // Cell 2,2
      emitters.add(
          1,
          FieldEmitter.create(
            targetChannel: 0,
            emissionRate: 100.0,
            radius: 20.0,
            falloffType: 1, // Gaussian
            isActive: true,
          ));

      system.update(1.0);

      // Distance 0, normalized 0, exp(0) = 1.0
      expect(channel0.getValue(2, 2), 100.0);

      // Distance 10, normalized 0.5, exp(-3 * 0.5^2) = exp(-0.75) = 0.472
      expect(channel0.getValue(1, 2), closeTo(47.2, 0.1));
    });

    test('Multiple entities on different channels', () {
      positions.add(1, Position.create(5.0, 5.0));
      emitters.add(
          1,
          FieldEmitter.create(
            targetChannel: 0,
            emissionRate: 10.0,
            radius: 5.0,
            falloffType: 2,
          ));

      positions.add(2, Position.create(15.0, 15.0));
      emitters.add(
          2,
          FieldEmitter.create(
            targetChannel: 1,
            emissionRate: 20.0,
            radius: 5.0,
            falloffType: 2,
          ));

      system.update(1.0);

      expect(channel0.getValue(0, 0), 10.0);
      expect(channel0.getValue(1, 1), 0.0);

      expect(channel1.getValue(0, 0), 0.0);
      expect(channel1.getValue(1, 1), 20.0);
    });

    test('Zero dt does nothing', () {
      positions.add(1, Position.create(5.0, 5.0));
      emitters.add(
          1,
          FieldEmitter.create(
            targetChannel: 0,
            emissionRate: 10.0,
            radius: 5.0,
            falloffType: 2,
          ));

      system.update(0.0);

      expect(channel0.getValue(0, 0), 0.0);
    });

    test('Zero radius does nothing', () {
      positions.add(1, Position.create(5.0, 5.0));
      emitters.add(
          1,
          FieldEmitter.create(
            targetChannel: 0,
            emissionRate: 10.0,
            radius: 0.0,
            falloffType: 2,
          ));

      system.update(1.0);

      expect(channel0.getValue(0, 0), 0.0);
    });
  });
}
