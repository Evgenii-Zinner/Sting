import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/radial_dial.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/radial_dial_system.dart';

void main() {
  group('RadialDialSystem', () {
    late ComponentStorage<RadialDial> dials;
    late RadialDialSystem system;

    setUp(() {
      dials = ComponentStorage<RadialDial>(10);
      system = RadialDialSystem(dials);
    });

    test('handlePointerDown detects hits within the ring', () {
      final dial = RadialDial.create(
        centerX: 100,
        centerY: 100,
        outerRadius: 50,
        innerRadius: 30,
      );
      dials.add(1, dial);

      // Misses: inside inner radius
      bool hit = system.handlePointerDown(100, 100);
      expect(hit, isFalse);
      expect(dial.isDragging, 0.0);

      // Misses: outside outer radius
      hit = system.handlePointerDown(160, 100);
      expect(hit, isFalse);
      expect(dial.isDragging, 0.0);

      // Hits: inside the ring
      hit = system.handlePointerDown(140, 100);
      expect(hit, isTrue);
      expect(dial.isDragging, 1.0);
    });

    test('handlePointerMove updates currentValue correctly', () {
      final dial = RadialDial.create(
        centerX: 100,
        centerY: 100,
        outerRadius: 50,
        innerRadius: 30,
        startAngle: 0.0,
        endAngle: pi, // 180 degrees
      );
      dials.add(1, dial);

      // Drag starts
      system.handlePointerDown(140, 100); // 0 degrees
      expect(dial.currentValue, closeTo(0.0, 0.001));

      // Move to 90 degrees
      system.handlePointerMove(100, 140);
      expect(dial.currentValue, closeTo(0.5, 0.001));

      // Move to 180 degrees
      system.handlePointerMove(60, 100);
      expect(dial.currentValue, closeTo(1.0, 0.001));
    });

    test('clamping keeps value between min and max angle boundaries', () {
      final dial = RadialDial.create(
        centerX: 100,
        centerY: 100,
        outerRadius: 50,
        innerRadius: 30,
        startAngle: 0.0,
        endAngle: pi,
      );
      dials.add(1, dial);

      system.handlePointerDown(140, 100);

      // Move to -90 degrees, should clamp to start (0.0) or end (1.0) depending on which is closer
      // For -90 degrees, angle is -pi/2, which wraps to 3pi/2.
      // Dist to start(0) = pi/2, Dist to end(pi) = pi/2. They are equal, depends on implementation,
      // but should be bounded.
      // Let's test a point clearly closer to 0: -45 degrees
      system.handlePointerMove(100 + 40, 100 - 40);
      expect(dial.currentValue, closeTo(0.0, 0.001));

      // Test a point clearly closer to pi: 225 degrees (or -135 degrees)
      system.handlePointerMove(100 - 40, 100 - 40);
      expect(dial.currentValue, closeTo(1.0, 0.001));
    });

    test('scaledValue calculates correctly', () {
      final dial = RadialDial.create(
        centerX: 100,
        centerY: 100,
        outerRadius: 50,
        innerRadius: 30,
        minValue: -10,
        maxValue: 10,
      );
      dials.add(1, dial);

      dial.currentValue = 0.5;
      expect(dial.scaledValue, closeTo(0.0, 0.001));

      dial.currentValue = 1.0;
      expect(dial.scaledValue, closeTo(10.0, 0.001));

      dial.currentValue = 0.0;
      expect(dial.scaledValue, closeTo(-10.0, 0.001));
    });

    test('segments > 1 quantizes currentValue', () {
      final dial = RadialDial.create(
        centerX: 100,
        centerY: 100,
        outerRadius: 50,
        innerRadius: 30,
        startAngle: 0.0,
        endAngle: pi,
        segments: 4.0,
      );
      dials.add(1, dial);

      system.handlePointerDown(140, 100);

      // Move to around 30 degrees (value = 30/180 = 0.166)
      // Rounded to nearest 1/4 (0.25 segments) -> 0.25 (since 0.166 > 0.125)
      system.handlePointerMove(
          100 + 40 * cos(30 * pi / 180), 100 + 40 * sin(30 * pi / 180));
      expect(dial.currentValue, closeTo(0.25, 0.001));
    });

    test('handlePointerUp releases drag', () {
      final dial = RadialDial.create(
        centerX: 100,
        centerY: 100,
        outerRadius: 50,
        innerRadius: 30,
      );
      dials.add(1, dial);

      system.handlePointerDown(140, 100);
      expect(dial.isDragging, 1.0);

      system.handlePointerUp(140, 100);
      expect(dial.isDragging, 0.0);
    });

    test('render executes without errors (zero-allocation)', () {
      final dial = RadialDial.create(
        centerX: 100,
        centerY: 100,
        outerRadius: 50,
        innerRadius: 30,
      );
      dials.add(1, dial);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Check if it renders successfully
      expect(() => system.render(canvas), returnsNormally);
    });
  });
}
