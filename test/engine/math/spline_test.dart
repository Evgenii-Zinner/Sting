import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/spline.dart';

void main() {
  group('SplineMath', () {
    test('evaluateQuadraticBezier', () {
      // Start point
      var (x, y) = SplineMath.evaluateQuadraticBezier(0, 0, 5, 10, 10, 0, 0.0);
      expect(x, closeTo(0.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // End point
      (x, y) = SplineMath.evaluateQuadraticBezier(0, 0, 5, 10, 10, 0, 1.0);
      expect(x, closeTo(10.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // Mid point
      (x, y) = SplineMath.evaluateQuadraticBezier(0, 0, 5, 10, 10, 0, 0.5);
      expect(x, closeTo(5.0, 1e-6));
      expect(y, closeTo(5.0, 1e-6));
    });

    test('evaluateCubicBezier', () {
      // Start point
      var (x, y) = SplineMath.evaluateCubicBezier(0, 0, 0, 10, 10, 10, 10, 0, 0.0);
      expect(x, closeTo(0.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // End point
      (x, y) = SplineMath.evaluateCubicBezier(0, 0, 0, 10, 10, 10, 10, 0, 1.0);
      expect(x, closeTo(10.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // Mid point
      (x, y) = SplineMath.evaluateCubicBezier(0, 0, 0, 10, 10, 10, 10, 0, 0.5);
      expect(x, closeTo(5.0, 1e-6));
      expect(y, closeTo(7.5, 1e-6));
    });

    test('evaluateHermite', () {
      // Start point
      var (x, y) = SplineMath.evaluateHermite(0, 0, 10, 10, 10, 0, -10, 10, 0.0);
      expect(x, closeTo(0.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // End point
      (x, y) = SplineMath.evaluateHermite(0, 0, 10, 10, 10, 0, -10, 10, 1.0);
      expect(x, closeTo(10.0, 1e-6));
      expect(y, closeTo(0.0, 1e-6));

      // Mid point (t=0.5)
      // h00 = 0.5, h10 = 0.125, h01 = 0.5, h11 = -0.125
      // x = 0.5*0 + 0.125*10 + 0.5*10 + -0.125*(-10) = 0 + 1.25 + 5 + 1.25 = 7.5
      // y = 0.5*0 + 0.125*10 + 0.5*0 + -0.125*10 = 0 + 1.25 + 0 - 1.25 = 0.0
      (x, y) = SplineMath.evaluateHermite(0, 0, 10, 10, 10, 0, -10, 10, 0.5);
      expect(x, closeTo(7.5, 1e-6));
      expect(y, closeTo(0.0, 1e-6));
    });
  });
}
