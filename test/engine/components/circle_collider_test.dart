import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/circle_collider.dart';

void main() {
  group('CircleCollider', () {
    test('creates and gets values correctly', () {
      final circle = CircleCollider.create(10.5);

      expect(circle.radius, 10.5);
    });

    test('sets values correctly', () {
      final circle = CircleCollider.create(0.0);

      circle.radius = 15.0;

      expect(circle.radius, 15.0);
    });

    test('is backed by Float32List', () {
      final circle = CircleCollider.create(5.0);
      expect(circle.data, isA<Float32List>());
      expect(circle.data.length, 1);
    });
  });
}
