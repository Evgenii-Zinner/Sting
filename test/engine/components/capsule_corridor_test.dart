import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/capsule_corridor.dart';

void main() {
  group('CapsuleCorridor Component', () {
    test('create factory initializes properties correctly', () {
      final corridor = CapsuleCorridor.create(
        startX: 10.0,
        startY: 20.0,
        endX: 100.0,
        endY: 200.0,
        radius: 15.0,
        frictionOverride: 0.05,
        speedBoost: 1.5,
        energyRechargeRate: 2.0,
        flowDirectionX: 0.707,
        flowDirectionY: 0.707,
        flowForce: 50.0,
      );

      expect(corridor.startX, closeTo(10.0, 0.0001));
      expect(corridor.startY, closeTo(20.0, 0.0001));
      expect(corridor.endX, closeTo(100.0, 0.0001));
      expect(corridor.endY, closeTo(200.0, 0.0001));
      expect(corridor.radius, closeTo(15.0, 0.0001));
      expect(corridor.frictionOverride, closeTo(0.05, 0.0001));
      expect(corridor.speedBoost, closeTo(1.5, 0.0001));
      expect(corridor.energyRechargeRate, closeTo(2.0, 0.0001));
      expect(corridor.flowDirectionX, closeTo(0.707, 0.0001));
      expect(corridor.flowDirectionY, closeTo(0.707, 0.0001));
      expect(corridor.flowForce, closeTo(50.0, 0.0001));
    });

    test('setters update properties', () {
      final corridor = CapsuleCorridor.create(
        startX: 0.0, startY: 0.0, endX: 0.0, endY: 0.0, radius: 0.0
      );

      corridor.startX = 5.0;
      expect(corridor.startX, closeTo(5.0, 0.0001));

      corridor.flowForce = 100.0;
      expect(corridor.flowForce, closeTo(100.0, 0.0001));
    });

    test('distanceToPoint calculates correct distance', () {
      final corridor = CapsuleCorridor.create(
        startX: 0.0,
        startY: 0.0,
        endX: 100.0,
        endY: 0.0,
        radius: 10.0,
      );

      // Point exactly on the line
      expect(corridor.distanceToPoint(50.0, 0.0), closeTo(0.0, 0.0001));

      // Point parallel to the line, above
      expect(corridor.distanceToPoint(50.0, 20.0), closeTo(20.0, 0.0001));

      // Point past the start (projection clamped to startX, startY)
      // distance from (-10, 0) to (0, 0) is 10
      expect(corridor.distanceToPoint(-10.0, 0.0), closeTo(10.0, 0.0001));

      // Point past the end
      // distance from (110, 10) to (100, 0) is sqrt(10^2 + 10^2) = 14.142
      expect(corridor.distanceToPoint(110.0, 10.0), closeTo(14.14213, 0.0001));
    });

    test('containsPoint checks containment correctly', () {
      final corridor = CapsuleCorridor.create(
        startX: 0.0,
        startY: 0.0,
        endX: 100.0,
        endY: 0.0,
        radius: 10.0,
      );

      // Point exactly on the line
      expect(corridor.containsPoint(50.0, 0.0), isTrue);

      // Point just inside radius
      expect(corridor.containsPoint(50.0, 9.9), isTrue);

      // Point exactly on radius
      expect(corridor.containsPoint(50.0, 10.0), isTrue);

      // Point just outside radius
      expect(corridor.containsPoint(50.0, 10.1), isFalse);

      // Point past start, inside half-circle radius
      expect(corridor.containsPoint(-9.9, 0.0), isTrue);

      // Point past start, outside half-circle radius
      expect(corridor.containsPoint(-10.1, 0.0), isFalse);
    });

    test('distanceToPoint handles zero length corridor', () {
      final corridor = CapsuleCorridor.create(
        startX: 10.0,
        startY: 10.0,
        endX: 10.0,
        endY: 10.0,
        radius: 5.0,
      );

      // Distance from (10, 10) to (13, 14) is 5
      expect(corridor.distanceToPoint(13.0, 14.0), closeTo(5.0, 0.0001));

      // Containment works for zero length
      expect(corridor.containsPoint(13.0, 14.0), isTrue);
      expect(corridor.containsPoint(14.0, 14.0), isFalse);
    });
  });
}
