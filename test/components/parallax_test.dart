import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/parallax.dart';
import 'dart:typed_data';

void main() {
  group('Parallax Component', () {
    test('create initializes values correctly', () {
      final parallax = Parallax.create(0.5, 0.2, 100.0, 200.0);

      expect(parallax.scrollFactorX, closeTo(0.5, 0.001));
      expect(parallax.scrollFactorY, closeTo(0.2, 0.001));
      expect(parallax.basePositionX, closeTo(100.0, 0.001));
      expect(parallax.basePositionY, closeTo(200.0, 0.001));
    });

    test('getters and setters work correctly', () {
      final parallax = Parallax(Float32List(4));

      parallax.scrollFactorX = 0.8;
      parallax.scrollFactorY = 0.4;
      parallax.basePositionX = 50.0;
      parallax.basePositionY = 75.0;

      expect(parallax.scrollFactorX, closeTo(0.8, 0.001));
      expect(parallax.scrollFactorY, closeTo(0.4, 0.001));
      expect(parallax.basePositionX, closeTo(50.0, 0.001));
      expect(parallax.basePositionY, closeTo(75.0, 0.001));
    });
  });
}
