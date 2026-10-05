import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/compound_mass_calculator.dart';

void main() {
  group('CompoundMassCalculator', () {
    test('calculateCenterOfMass calculates correctly for symmetric bodies', () {
      final masses = Float32List.fromList([10.0, 10.0]);
      final positionsX = Float32List.fromList([-5.0, 5.0]);
      final positionsY = Float32List.fromList([0.0, 0.0]);

      final (totalMass, comX, comY) =
          CompoundMassCalculator.calculateCenterOfMass(
              masses, positionsX, positionsY, 2);

      expect(totalMass, closeTo(20.0, 1e-5));
      expect(comX, closeTo(0.0, 1e-5));
      expect(comY, closeTo(0.0, 1e-5));
    });

    test('calculateCenterOfMass calculates correctly for asymmetric bodies',
        () {
      final masses = Float32List.fromList([10.0, 30.0]);
      final positionsX = Float32List.fromList([-5.0, 5.0]);
      final positionsY = Float32List.fromList([2.0, -2.0]);

      final (totalMass, comX, comY) =
          CompoundMassCalculator.calculateCenterOfMass(
              masses, positionsX, positionsY, 2);

      expect(totalMass, closeTo(40.0, 1e-5));
      // comX = (10 * -5 + 30 * 5) / 40 = 100 / 40 = 2.5
      expect(comX, closeTo(2.5, 1e-5));
      // comY = (10 * 2 + 30 * -2) / 40 = -40 / 40 = -1.0
      expect(comY, closeTo(-1.0, 1e-5));
    });

    test('calculateCenterOfMass handles zero mass gracefully', () {
      final masses = Float32List.fromList([0.0, 0.0]);
      final positionsX = Float32List.fromList([-5.0, 5.0]);
      final positionsY = Float32List.fromList([0.0, 0.0]);

      final (totalMass, comX, comY) =
          CompoundMassCalculator.calculateCenterOfMass(
              masses, positionsX, positionsY, 2);

      expect(totalMass, 0.0);
      expect(comX, 0.0);
      expect(comY, 0.0);
    });

    test(
        'calculateMomentOfInertia2D calculates correctly using Parallel Axis Theorem',
        () {
      final masses = Float32List.fromList([10.0, 10.0]);
      final positionsX = Float32List.fromList([-5.0, 5.0]);
      final positionsY = Float32List.fromList([0.0, 0.0]);
      final inertias = Float32List.fromList([50.0, 50.0]);

      // COM should be at (0, 0)
      final (_, comX, comY) = CompoundMassCalculator.calculateCenterOfMass(
          masses, positionsX, positionsY, 2);

      final totalInertia = CompoundMassCalculator.calculateMomentOfInertia2D(
          masses, positionsX, positionsY, inertias, 2, comX, comY);

      // Inertia for each = I_i + m_i * d^2
      // d^2 for both is 25.0
      // I_1 = 50.0 + 10.0 * 25.0 = 50.0 + 250.0 = 300.0
      // I_2 = 50.0 + 10.0 * 25.0 = 50.0 + 250.0 = 300.0
      // Total = 600.0
      expect(totalInertia, closeTo(600.0, 1e-5));
    });

    test('calculateMomentOfInertia2D works for asymmetric assemblies', () {
      final masses = Float32List.fromList([10.0, 30.0]);
      final positionsX = Float32List.fromList([-5.0, 5.0]);
      final positionsY = Float32List.fromList([2.0, -2.0]);
      final inertias = Float32List.fromList([50.0, 150.0]);

      final (_, comX, comY) = CompoundMassCalculator.calculateCenterOfMass(
          masses, positionsX, positionsY, 2);

      final totalInertia = CompoundMassCalculator.calculateMomentOfInertia2D(
          masses, positionsX, positionsY, inertias, 2, comX, comY);

      // comX = 2.5, comY = -1.0
      // Body 1: dx = -5 - 2.5 = -7.5, dy = 2 - -1 = 3
      // dSq1 = 56.25 + 9 = 65.25
      // I_1 = 50 + 10 * 65.25 = 50 + 652.5 = 702.5
      // Body 2: dx = 5 - 2.5 = 2.5, dy = -2 - -1 = -1
      // dSq2 = 6.25 + 1 = 7.25
      // I_2 = 150 + 30 * 7.25 = 150 + 217.5 = 367.5
      // Total = 702.5 + 367.5 = 1070.0
      expect(totalInertia, closeTo(1070.0, 1e-5));
    });

    test('calculateMomentOfInertia2D ignores elements beyond count', () {
      final masses = Float32List.fromList([10.0, 10.0, 100.0]);
      final positionsX = Float32List.fromList([-5.0, 5.0, 100.0]);
      final positionsY = Float32List.fromList([0.0, 0.0, 100.0]);
      final inertias = Float32List.fromList([50.0, 50.0, 1000.0]);

      final (_, comX, comY) = CompoundMassCalculator.calculateCenterOfMass(
          masses, positionsX, positionsY, 2);

      final totalInertia = CompoundMassCalculator.calculateMomentOfInertia2D(
          masses, positionsX, positionsY, inertias, 2, comX, comY);

      expect(totalInertia, closeTo(600.0, 1e-5));
    });
  });
}
