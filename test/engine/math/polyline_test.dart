import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/polyline.dart';

void main() {
  group('PolylineMath', () {
    test('length', () {
      final points = Float32List.fromList([
        0.0, 0.0,
        10.0, 0.0,
        10.0, 10.0,
      ]);

      expect(PolylineMath.length(points), 20.0);
    });

    test('length returns 0 for less than 2 points', () {
      expect(PolylineMath.length(Float32List.fromList([0.0, 0.0])), 0.0);
      expect(PolylineMath.length(Float32List.fromList([])), 0.0);
    });

    test('evaluateAtDistance', () {
      final points = Float32List.fromList([
        0.0, 0.0,
        10.0, 0.0,
        10.0, 10.0,
      ]);

      // Start
      var (x, y) = PolylineMath.evaluateAtDistance(points, 0.0);
      expect(x, closeTo(0.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // Middle of first segment
      (x, y) = PolylineMath.evaluateAtDistance(points, 5.0);
      expect(x, closeTo(5.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // Exact corner
      (x, y) = PolylineMath.evaluateAtDistance(points, 10.0);
      expect(x, closeTo(10.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // Middle of second segment
      (x, y) = PolylineMath.evaluateAtDistance(points, 15.0);
      expect(x, closeTo(10.0, 1e-6));
      expect(y, closeTo(5.0, 1e-6));

      // End
      (x, y) = PolylineMath.evaluateAtDistance(points, 20.0);
      expect(x, closeTo(10.0, 1e-6));
      expect(y, closeTo(10.0, 1e-6));

      // Past end
      (x, y) = PolylineMath.evaluateAtDistance(points, 25.0);
      expect(x, closeTo(10.0, 1e-6));
      expect(y, closeTo(10.0, 1e-6));
    });

    test('evaluateAt', () {
      final points = Float32List.fromList([
        0.0, 0.0,
        10.0, 0.0,
        10.0, 10.0,
      ]);

      // t = 0.0
      var (x, y) = PolylineMath.evaluateAt(points, 0.0);
      expect(x, closeTo(0.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // t = 0.25 (distance 5)
      (x, y) = PolylineMath.evaluateAt(points, 0.25);
      expect(x, closeTo(5.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // t = 0.5 (distance 10, exact corner)
      (x, y) = PolylineMath.evaluateAt(points, 0.5);
      expect(x, closeTo(10.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // t = 0.75 (distance 15)
      (x, y) = PolylineMath.evaluateAt(points, 0.75);
      expect(x, closeTo(10.0, 1e-6));
      expect(y, closeTo(5.0, 1e-6));

      // t = 1.0 (distance 20)
      (x, y) = PolylineMath.evaluateAt(points, 1.0);
      expect(x, closeTo(10.0, 1e-6));
      expect(y, closeTo(10.0, 1e-6));
    });

    test('evaluateAt handles empty and single-point polylines', () {
      var (x, y) = PolylineMath.evaluateAt(Float32List.fromList([]), 0.5);
      expect(x, 0.0);
      expect(y, 0.0);

      (x, y) = PolylineMath.evaluateAt(Float32List.fromList([5.0, 5.0]), 0.5);
      expect(x, 5.0);
      expect(y, 5.0);
    });
  });
}
