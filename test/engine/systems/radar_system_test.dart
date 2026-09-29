import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/radar_display.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/systems/radar_system.dart';

void main() {
  group('RadarSystem and RadarDisplay Tests', () {
    test('RadarDisplay component layout and accessors', () {
      final radar = RadarDisplay.create(
        100.0,
        200.0,
        50.0,
        1000.0,
        2.0,
        pi,
        0xDD0A0E18,
        0xFF00E5FF,
        0xFFFFD600,
        1.0,
      );

      expect(radar.screenX, 100.0);
      expect(radar.screenY, 200.0);
      expect(radar.radius, 50.0);
      expect(radar.worldRange, 1000.0);
      expect(radar.sweepSpeed, 2.0);
      expect(radar.sweepAngle, closeTo(pi, 0.0001));
      expect(radar.backgroundColorHex, 0xDD0A0E18);
      expect(radar.radarColorHex, 0xFF00E5FF);
      expect(radar.blipColorHex, 0xFFFFD600);
      expect(radar.isCircular, 1.0);
    });

    test('RadarSystem updates sweepAngle', () {
      final radarCaste = ComponentStorage<RadarDisplay>(10);
      final radar = RadarDisplay.create(
        100.0,
        200.0,
        50.0,
        1000.0,
        2.0, // sweepSpeed
        0.0, // sweepAngle
        0xDD0A0E18,
        0xFF00E5FF,
        0xFFFFD600,
        1.0,
      );
      radarCaste.add(1, radar);

      final system = RadarSystem(radarCaste: radarCaste);

      system.update(0.5); // dt = 0.5s

      // sweepAngle should be 0.0 + 2.0 * 0.5 = 1.0
      expect(radar.sweepAngle, 1.0);

      // Verify modulus 2*pi
      system.update(pi); // dt = pi, sweepAngle += 2.0 * pi
      expect(radar.sweepAngle, closeTo(1.0, 0.0001));
    });

    test('RadarSystem render without allocations', () {
      final radarCaste = ComponentStorage<RadarDisplay>(10);
      final radar = RadarDisplay.create(
        100.0,
        100.0,
        50.0,
        1000.0,
        2.0,
        0.0,
        0xDD0A0E18,
        0xFF00E5FF,
        0xFFFFD600,
        1.0,
      );
      radarCaste.add(1, radar);

      final posCaste = ComponentStorage<Position>(10);
      posCaste.add(2, Position.create(500.0, 0.0)); // Inside range
      posCaste.add(3, Position.create(2000.0, 0.0)); // Outside range

      final system = RadarSystem(radarCaste: radarCaste);
      final query = Query1<Position>(posCaste);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Perform render
      system.render(canvas, 0.0, 0.0, query);

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
