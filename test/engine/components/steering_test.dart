import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/steering.dart';
import 'dart:typed_data';

void main() {
  group('Steering Component', () {
    test('creates and stores values correctly', () {
      final steering = Steering.create(
        targetX: 100.0,
        targetY: 50.0,
        maxSpeed: 200.0,
        maxForce: 20.0,
        behavior: Steering.behaviorFlee,
        decelerationRadius: 75.0,
      );

      expect(steering.targetX, 100.0);
      expect(steering.targetY, 50.0);
      expect(steering.maxSpeed, 200.0);
      expect(steering.maxForce, 20.0);
      expect(steering.behavior, Steering.behaviorFlee);
      expect(steering.decelerationRadius, 75.0);
    });

    test('mutates values correctly', () {
      final steering = Steering.create();

      steering.targetX = 10.0;
      steering.targetY = -20.0;
      steering.maxSpeed = 50.0;
      steering.maxForce = 5.0;
      steering.behavior = Steering.behaviorArrive;
      steering.decelerationRadius = 10.0;

      expect(steering.targetX, 10.0);
      expect(steering.targetY, -20.0);
      expect(steering.maxSpeed, 50.0);
      expect(steering.maxForce, 5.0);
      expect(steering.behavior, Steering.behaviorArrive);
      expect(steering.decelerationRadius, 10.0);
    });
  });
}
