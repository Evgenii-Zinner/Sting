import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/preferred_velocity.dart';

void main() {
  group('PreferredVelocity Component Tests', () {
    test('create initializes values correctly', () {
      final preferredVelocity = PreferredVelocity.create(1.5, -2.5);

      expect(preferredVelocity.dx, closeTo(1.5, 0.0001));
      expect(preferredVelocity.dy, closeTo(-2.5, 0.0001));
    });

    test('getters and setters work correctly', () {
      final preferredVelocity = PreferredVelocity.create(0.0, 0.0);

      preferredVelocity.dx = 3.14;
      preferredVelocity.dy = -1.23;

      expect(preferredVelocity.dx, closeTo(3.14, 0.0001));
      expect(preferredVelocity.dy, closeTo(-1.23, 0.0001));
    });

    test('is backed by Float32List', () {
      final preferredVelocity = PreferredVelocity.create(1.0, 1.0);
      expect(preferredVelocity, isA<Float32List>());
    });
  });
}
