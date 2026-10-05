import 'dart:math' as math;
import 'dart:typed_data';

class SpatialResonance {
  /// Evaluates a Gaussian falloff function.
  /// [distanceSq]: The squared distance from the center.
  /// [radiusSq]: The squared radius representing the falloff extent.
  /// [peakValue]: The maximum value at distance 0.
  static double gaussianFalloff(
      double distanceSq, double radiusSq, double peakValue) {
    if (radiusSq <= 0.0) {
      return distanceSq <= 0.0 ? peakValue : 0.0;
    }
    return peakValue * math.exp(-distanceSq / radiusSq);
  }

  /// Evaluates an inverse-square falloff function with a softening factor.
  /// [distanceSq]: The squared distance from the center.
  /// [softeningFactor]: A small value added to the denominator to prevent division by zero and cap the maximum value.
  /// [intensity]: The base intensity of the source.
  static double inverseSquareFalloff(
      double distanceSq, double softeningFactor, double intensity) {
    double denom = distanceSq + softeningFactor;
    if (denom == 0.0) {
      if (intensity == 0.0) return 0.0;
      return intensity > 0.0 ? double.infinity : double.negativeInfinity;
    }
    return intensity / denom;
  }

  /// Evaluates a smoothstep falloff function.
  /// Returns 1.0 within [innerRadius] and smoothly interpolates to 0.0 at [outerRadius].
  static double smoothstepFalloff(
      double distance, double innerRadius, double outerRadius) {
    if (outerRadius <= innerRadius) {
      return distance <= innerRadius ? 1.0 : 0.0;
    }
    if (distance <= innerRadius) return 1.0;
    if (distance >= outerRadius) return 0.0;

    double t = (distance - innerRadius) / (outerRadius - innerRadius);
    return 1.0 - (t * t * (3.0 - 2.0 * t));
  }

  /// Evaluates a quintic Hermite falloff function (smoother step).
  /// [normalizedDistance]: A value between 0.0 and 1.0.
  static double quinticHermiteFalloff(double normalizedDistance) {
    if (normalizedDistance <= 0.0) return 1.0;
    if (normalizedDistance >= 1.0) return 0.0;

    double t = normalizedDistance;
    double t3 = t * t * t;
    double t4 = t3 * t;
    double t5 = t4 * t;

    // 1 - (10t^3 - 15t^4 + 6t^5)
    return 1.0 - (10.0 * t3 - 15.0 * t4 + 6.0 * t5);
  }

  /// Batch evaluates Gaussian falloff over arrays of squared distances.
  /// Writes results into [outBuffer] with zero allocations.
  static void evaluateArrayFalloff(Float32List outBuffer,
      Float32List distSqBuffer, int count, double radiusSq, double peakValue) {
    if (radiusSq <= 0.0) {
      for (int i = 0; i < count; i++) {
        outBuffer[i] = distSqBuffer[i] <= 0.0 ? peakValue : 0.0;
      }
      return;
    }

    for (int i = 0; i < count; i++) {
      outBuffer[i] = peakValue * math.exp(-distSqBuffer[i] / radiusSq);
    }
  }
}
