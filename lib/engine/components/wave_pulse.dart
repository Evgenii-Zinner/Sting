import 'dart:math' as math;
import 'dart:typed_data';

/// A WavePulse component representing an expanding radial wave.
/// Backed by a Float32List(10) for zero-allocation performance.
///
/// Layout:
/// - Index 0: originX
/// - Index 1: originY
/// - Index 2: currentRadius
/// - Index 3: maxRadius
/// - Index 4: expansionSpeed
/// - Index 5: initialAmplitude
/// - Index 6: currentAmplitude
/// - Index 7: decayRate
/// - Index 8: ringThickness
/// - Index 9: isActive (1.0 for true, 0.0 for false)
extension type WavePulse(Float32List data) {
  /// Creates a new WavePulse.
  WavePulse.create({
    required double originX,
    required double originY,
    required double maxRadius,
    required double expansionSpeed,
    double initialAmplitude = 1.0,
    double decayRate = 1.0,
    double ringThickness = 10.0,
  }) : this(Float32List(10)
          ..[0] = originX
          ..[1] = originY
          ..[2] = 0.0
          ..[3] = maxRadius
          ..[4] = expansionSpeed
          ..[5] = initialAmplitude
          ..[6] = initialAmplitude
          ..[7] = decayRate
          ..[8] = ringThickness
          ..[9] = 1.0);

  double get originX => data[0];
  set originX(double value) => data[0] = value;

  double get originY => data[1];
  set originY(double value) => data[1] = value;

  double get currentRadius => data[2];
  set currentRadius(double value) => data[2] = value;

  double get maxRadius => data[3];
  set maxRadius(double value) => data[3] = value;

  double get expansionSpeed => data[4];
  set expansionSpeed(double value) => data[4] = value;

  double get initialAmplitude => data[5];
  set initialAmplitude(double value) => data[5] = value;

  double get currentAmplitude => data[6];
  set currentAmplitude(double value) => data[6] = value;

  double get decayRate => data[7];
  set decayRate(double value) => data[7] = value;

  double get ringThickness => data[8];
  set ringThickness(double value) => data[8] = value;

  bool get isActive => data[9] > 0.5;
  set isActive(bool value) => data[9] = value ? 1.0 : 0.0;

  /// Returns true if the point (x, y) is within the current wave ring.
  bool containsPoint(double x, double y) {
    if (!isActive) return false;

    final dx = x - originX;
    final dy = y - originY;
    final distanceSq = dx * dx + dy * dy;

    final halfThickness = ringThickness * 0.5;
    final innerRadius = math.max(0.0, currentRadius - halfThickness);
    final outerRadius = currentRadius + halfThickness;

    // Fast rejection based on squared distance to avoid sqrt if possible
    if (distanceSq < innerRadius * innerRadius ||
        distanceSq > outerRadius * outerRadius) {
      return false;
    }

    final distance = math.sqrt(distanceSq);
    return distance >= innerRadius && distance <= outerRadius;
  }
}
