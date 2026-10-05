import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/spatial_resonance.dart';

void main() {
  group('SpatialResonance', () {
    group('gaussianFalloff', () {
      test('evaluates correctly for positive radiusSq', () {
        expect(SpatialResonance.gaussianFalloff(0.0, 10.0, 5.0), equals(5.0));
        // exp(-1) = 0.36787944117
        expect(SpatialResonance.gaussianFalloff(10.0, 10.0, 5.0),
            closeTo(5.0 * 0.367879, 0.0001));
        // exp(-2) = 0.13533528323
        expect(SpatialResonance.gaussianFalloff(20.0, 10.0, 5.0),
            closeTo(5.0 * 0.135335, 0.0001));
      });

      test('handles radiusSq <= 0.0 gracefully', () {
        expect(SpatialResonance.gaussianFalloff(0.0, 0.0, 5.0), equals(5.0));
        expect(SpatialResonance.gaussianFalloff(1.0, 0.0, 5.0), equals(0.0));
        expect(SpatialResonance.gaussianFalloff(0.0, -1.0, 5.0), equals(5.0));
        expect(SpatialResonance.gaussianFalloff(1.0, -1.0, 5.0), equals(0.0));
      });

      test('handles distanceSq < 0.0 gracefully when radiusSq <= 0.0', () {
        expect(SpatialResonance.gaussianFalloff(-1.0, 0.0, 5.0), equals(5.0));
      });
    });

    group('inverseSquareFalloff', () {
      test('evaluates correctly with softening factor', () {
        expect(SpatialResonance.inverseSquareFalloff(0.0, 1.0, 10.0),
            equals(10.0));
        expect(
            SpatialResonance.inverseSquareFalloff(4.0, 1.0, 10.0), equals(2.0));
        expect(
            SpatialResonance.inverseSquareFalloff(9.0, 1.0, 10.0), equals(1.0));
      });

      test('handles zero denominator gracefully', () {
        expect(
            SpatialResonance.inverseSquareFalloff(0.0, 0.0, 0.0), equals(0.0));
        expect(SpatialResonance.inverseSquareFalloff(0.0, 0.0, 10.0),
            equals(double.infinity));
        expect(SpatialResonance.inverseSquareFalloff(0.0, 0.0, -10.0),
            equals(double.negativeInfinity));
        expect(SpatialResonance.inverseSquareFalloff(1.0, -1.0, 10.0),
            equals(double.infinity));
      });
    });

    group('smoothstepFalloff', () {
      test('evaluates correctly within bounds', () {
        expect(SpatialResonance.smoothstepFalloff(0.0, 2.0, 10.0), equals(1.0));
        expect(SpatialResonance.smoothstepFalloff(2.0, 2.0, 10.0), equals(1.0));
        expect(
            SpatialResonance.smoothstepFalloff(10.0, 2.0, 10.0), equals(0.0));
        expect(
            SpatialResonance.smoothstepFalloff(12.0, 2.0, 10.0), equals(0.0));

        // midpoint (distance 6.0, t = 0.5) -> 1 - (0.5^2 * (3 - 2*0.5)) = 1 - (0.25 * 2) = 0.5
        expect(SpatialResonance.smoothstepFalloff(6.0, 2.0, 10.0), equals(0.5));
      });

      test('handles outerRadius <= innerRadius gracefully', () {
        expect(SpatialResonance.smoothstepFalloff(1.0, 2.0, 2.0), equals(1.0));
        expect(SpatialResonance.smoothstepFalloff(2.0, 2.0, 2.0), equals(1.0));
        expect(SpatialResonance.smoothstepFalloff(3.0, 2.0, 2.0), equals(0.0));

        expect(SpatialResonance.smoothstepFalloff(1.0, 2.0, 1.0), equals(1.0));
        expect(SpatialResonance.smoothstepFalloff(3.0, 2.0, 1.0), equals(0.0));
      });
    });

    group('quinticHermiteFalloff', () {
      test('evaluates correctly within bounds', () {
        expect(SpatialResonance.quinticHermiteFalloff(0.0), equals(1.0));
        expect(SpatialResonance.quinticHermiteFalloff(1.0), equals(0.0));
        expect(SpatialResonance.quinticHermiteFalloff(-0.5), equals(1.0));
        expect(SpatialResonance.quinticHermiteFalloff(1.5), equals(0.0));

        // midpoint (t = 0.5) -> 1 - (10*0.125 - 15*0.0625 + 6*0.03125) = 1 - (1.25 - 0.9375 + 0.1875) = 1 - 0.5 = 0.5
        expect(SpatialResonance.quinticHermiteFalloff(0.5), equals(0.5));
      });
    });

    group('evaluateArrayFalloff', () {
      test('evaluates batch correctly for positive radiusSq', () {
        final distSqBuffer = Float32List.fromList([0.0, 10.0, 20.0]);
        final outBuffer = Float32List(3);

        SpatialResonance.evaluateArrayFalloff(
            outBuffer, distSqBuffer, 3, 10.0, 5.0);

        expect(outBuffer[0], equals(5.0));
        expect(outBuffer[1], closeTo(5.0 * 0.367879, 0.0001));
        expect(outBuffer[2], closeTo(5.0 * 0.135335, 0.0001));
      });

      test('handles batch radiusSq <= 0.0 gracefully', () {
        final distSqBuffer = Float32List.fromList([0.0, 1.0, -1.0]);
        final outBuffer = Float32List(3);

        SpatialResonance.evaluateArrayFalloff(
            outBuffer, distSqBuffer, 3, 0.0, 5.0);

        expect(outBuffer[0], equals(5.0));
        expect(outBuffer[1], equals(0.0));
        expect(outBuffer[2], equals(5.0));

        SpatialResonance.evaluateArrayFalloff(
            outBuffer, distSqBuffer, 3, -1.0, 5.0);

        expect(outBuffer[0], equals(5.0));
        expect(outBuffer[1], equals(0.0));
        expect(outBuffer[2], equals(5.0));
      });
    });
  });
}
