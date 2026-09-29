import 'dart:math' as math;
import 'dart:typed_data';

/// A flat CapsuleCorridor component using a Dart extension type over a Float32List.
/// Layout (11 floats):
/// Index 0: startX, 1: startY, 2: endX, 3: endY
/// Index 4: radius (corridor half-width sweep)
/// Index 5: frictionOverride (e.g. 0.05 on highway, negative if none)
/// Index 6: speedBoost (e.g. 1.5 for 50% boost)
/// Index 7: energyRechargeRate (energy or heat added per second)
/// Index 8: flowDirectionX, 9: flowDirectionY (normalized direction along pipeline)
/// Index 10: flowForce (propulsion acceleration force)
extension type CapsuleCorridor(Float32List data) {
  /// Creates a new CapsuleCorridor.
  CapsuleCorridor.create({
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    required double radius,
    double frictionOverride = -1.0,
    double speedBoost = 1.0,
    double energyRechargeRate = 0.0,
    double flowDirectionX = 0.0,
    double flowDirectionY = 0.0,
    double flowForce = 0.0,
  }) : this(Float32List(11)
          ..[0] = startX
          ..[1] = startY
          ..[2] = endX
          ..[3] = endY
          ..[4] = radius
          ..[5] = frictionOverride
          ..[6] = speedBoost
          ..[7] = energyRechargeRate
          ..[8] = flowDirectionX
          ..[9] = flowDirectionY
          ..[10] = flowForce);

  double get startX => data[0];
  set startX(double value) => data[0] = value;

  double get startY => data[1];
  set startY(double value) => data[1] = value;

  double get endX => data[2];
  set endX(double value) => data[2] = value;

  double get endY => data[3];
  set endY(double value) => data[3] = value;

  double get radius => data[4];
  set radius(double value) => data[4] = value;

  double get frictionOverride => data[5];
  set frictionOverride(double value) => data[5] = value;

  double get speedBoost => data[6];
  set speedBoost(double value) => data[6] = value;

  double get energyRechargeRate => data[7];
  set energyRechargeRate(double value) => data[7] = value;

  double get flowDirectionX => data[8];
  set flowDirectionX(double value) => data[8] = value;

  double get flowDirectionY => data[9];
  set flowDirectionY(double value) => data[9] = value;

  double get flowForce => data[10];
  set flowForce(double value) => data[10] = value;

  /// Calculates the shortest distance from the given point [px], [py] to the corridor segment.
  double distanceToPoint(double px, double py) {
    final double sx = startX;
    final double sy = startY;
    final double ex = endX;
    final double ey = endY;

    final double l2 = (ex - sx) * (ex - sx) + (ey - sy) * (ey - sy);
    if (l2 == 0.0) {
      final double dx = px - sx;
      final double dy = py - sy;
      return math.sqrt(dx * dx + dy * dy);
    }
    double t = ((px - sx) * (ex - sx) + (py - sy) * (ey - sy)) / l2;
    t = math.max(0.0, math.min(1.0, t));

    final double projX = sx + t * (ex - sx);
    final double projY = sy + t * (ey - sy);

    final double dx = px - projX;
    final double dy = py - projY;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Returns true if the given point [px], [py] is inside the corridor.
  bool containsPoint(double px, double py) {
    return distanceToPoint(px, py) <= radius;
  }
}
