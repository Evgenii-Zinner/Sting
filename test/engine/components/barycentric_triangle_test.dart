import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/barycentric_triangle.dart';

void main() {
  group('BarycentricTriangle Component Tests', () {
    test('create() initializes correct defaults', () {
      final tri = BarycentricTriangle.create(
        centerX: 100.0,
        centerY: 200.0,
        radius: 50.0,
      );

      expect(tri.centerX, 100.0);
      expect(tri.centerY, 200.0);
      expect(tri.radius, 50.0);
      expect(tri.rotation, 0.0);

      // Default weights should be equal (1/3)
      expect(tri.weightA, closeTo(0.3333333, 0.0001));
      expect(tri.weightB, closeTo(0.3333333, 0.0001));
      expect(tri.weightC, closeTo(0.3333333, 0.0001));

      expect(tri.puckX, 0.0);
      expect(tri.puckY, 0.0);
      expect(tri.isDragging, 0.0);

      expect(tri.cornerAColorHex, 4294901760.0);
      expect(tri.cornerBColorHex, 4278255360.0);
      // 32-bit floats drop some precision. The initial value is 4278190335 (0xFF0000FF).
      // Due to 24-bit mantissa, it will be 4278190336.0
      expect(tri.cornerCColorHex, 4278190336.0);
      expect(tri.puckColorHex, 4294967296.0);

      expect(tri.strokeWidth, 2.0);
    });

    test('getters and setters work correctly', () {
      final data = Float32List(16);
      final tri = BarycentricTriangle(data);

      tri.centerX = 150.0;
      expect(tri.centerX, 150.0);
      expect(data[0], 150.0);

      tri.centerY = 250.0;
      expect(tri.centerY, 250.0);
      expect(data[1], 250.0);

      tri.radius = 75.0;
      expect(tri.radius, 75.0);
      expect(data[2], 75.0);

      tri.rotation = 1.5;
      expect(tri.rotation, 1.5);
      expect(data[3], 1.5);

      tri.weightA = 0.5;
      expect(tri.weightA, 0.5);
      expect(data[4], 0.5);

      tri.weightB = 0.25;
      expect(tri.weightB, 0.25);
      expect(data[5], 0.25);

      tri.weightC = 0.25;
      expect(tri.weightC, 0.25);
      expect(data[6], 0.25);

      tri.puckX = 10.0;
      expect(tri.puckX, 10.0);
      expect(data[7], 10.0);

      tri.puckY = 20.0;
      expect(tri.puckY, 20.0);
      expect(data[8], 20.0);

      tri.isDragging = 1.0;
      expect(tri.isDragging, 1.0);
      expect(data[9], 1.0);

      tri.cornerAColorHex = 123.0;
      expect(tri.cornerAColorHex, 123.0);
      expect(data[10], 123.0);

      tri.cornerBColorHex = 456.0;
      expect(tri.cornerBColorHex, 456.0);
      expect(data[11], 456.0);

      tri.cornerCColorHex = 789.0;
      expect(tri.cornerCColorHex, 789.0);
      expect(data[12], 789.0);

      tri.puckColorHex = 111.0;
      expect(tri.puckColorHex, 111.0);
      expect(data[13], 111.0);

      tri.strokeWidth = 5.0;
      expect(tri.strokeWidth, 5.0);
      expect(data[14], 5.0);
    });
  });
}
