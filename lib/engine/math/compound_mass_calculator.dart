import 'dart:typed_data';

class CompoundMassCalculator {
  /// Calculates the center of mass for a compound multi-part assembly.
  /// Returns a Dart 3 record containing the total mass, and the X and Y coordinates of the center of mass.
  /// Achieves zero heap allocations.
  static (double totalMass, double comX, double comY) calculateCenterOfMass(
      Float32List masses, Float32List positionsX, Float32List positionsY, int count) {
    double totalMass = 0.0;
    double weightedX = 0.0;
    double weightedY = 0.0;

    for (int i = 0; i < count; i++) {
      final double m = masses[i];
      totalMass += m;
      weightedX += m * positionsX[i];
      weightedY += m * positionsY[i];
    }

    if (totalMass == 0.0) {
      return (0.0, 0.0, 0.0);
    }

    return (totalMass, weightedX / totalMass, weightedY / totalMass);
  }

  /// Calculates the moment of inertia for a compound multi-part assembly 2D.
  /// Applies the Parallel Axis Theorem: I = sum(I_i + m_i * distanceSq).
  /// Achieves zero heap allocations.
  static double calculateMomentOfInertia2D(
      Float32List masses,
      Float32List localX,
      Float32List localY,
      Float32List localInertias,
      int count,
      double comX,
      double comY) {
    double totalInertia = 0.0;

    for (int i = 0; i < count; i++) {
      final double m = masses[i];
      final double dx = localX[i] - comX;
      final double dy = localY[i] - comY;
      final double distanceSq = dx * dx + dy * dy;

      totalInertia += localInertias[i] + m * distanceSq;
    }

    return totalInertia;
  }
}
