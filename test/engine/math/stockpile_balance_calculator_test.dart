import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/stockpile_balance_calculator.dart';

void main() {
  group('StockpileBalanceCalculator', () {
    test('computes averages and deficits/surpluses for a single component', () {
      final nodeStockpiles = Float32List.fromList([10.0, 20.0, 30.0, 40.0]);
      final componentLabels = Int32List.fromList([0, 0, 0, 0]);
      final int nodeCount = 4;

      final componentTotals = Float32List(1);
      final componentNodeCounts = Int32List(1);
      final componentAverages = Float32List(1);
      final outputDeltas = Float32List(nodeCount);

      StockpileBalanceCalculator.computeAverages(
        nodeStockpiles,
        componentLabels,
        nodeCount,
        componentTotals,
        componentNodeCounts,
        componentAverages,
      );

      // Total: 10 + 20 + 30 + 40 = 100, Average = 25
      expect(componentTotals[0], 100.0);
      expect(componentNodeCounts[0], 4);
      expect(componentAverages[0], 25.0);

      StockpileBalanceCalculator.computeDeficitsAndSurpluses(
        nodeStockpiles,
        componentLabels,
        componentAverages,
        nodeCount,
        outputDeltas,
      );

      // Deltas: 10-25=-15, 20-25=-5, 30-25=5, 40-25=15
      expect(outputDeltas[0], closeTo(-15.0, 1e-5));
      expect(outputDeltas[1], closeTo(-5.0, 1e-5));
      expect(outputDeltas[2], closeTo(5.0, 1e-5));
      expect(outputDeltas[3], closeTo(15.0, 1e-5));
    });

    test('computes correctly for multiple isolated components', () {
      final nodeStockpiles = Float32List.fromList([
        10.0,
        30.0,
        100.0,
        200.0,
        0.0,
        50.0,
      ]);
      final componentLabels = Int32List.fromList([0, 0, 1, 1, 2, 2]);
      final int nodeCount = 6;

      final componentTotals = Float32List(3);
      final componentNodeCounts = Int32List(3);
      final componentAverages = Float32List(3);
      final outputDeltas = Float32List(nodeCount);

      StockpileBalanceCalculator.computeAverages(
        nodeStockpiles,
        componentLabels,
        nodeCount,
        componentTotals,
        componentNodeCounts,
        componentAverages,
      );

      // Comp 0: 10 + 30 = 40 (Avg 20)
      // Comp 1: 100 + 200 = 300 (Avg 150)
      // Comp 2: 0 + 50 = 50 (Avg 25)
      expect(componentAverages[0], 20.0);
      expect(componentAverages[1], 150.0);
      expect(componentAverages[2], 25.0);

      StockpileBalanceCalculator.computeDeficitsAndSurpluses(
        nodeStockpiles,
        componentLabels,
        componentAverages,
        nodeCount,
        outputDeltas,
      );

      // Deltas for Comp 0
      expect(outputDeltas[0], closeTo(-10.0, 1e-5));
      expect(outputDeltas[1], closeTo(10.0, 1e-5));

      // Deltas for Comp 1
      expect(outputDeltas[2], closeTo(-50.0, 1e-5));
      expect(outputDeltas[3], closeTo(50.0, 1e-5));

      // Deltas for Comp 2
      expect(outputDeltas[4], closeTo(-25.0, 1e-5));
      expect(outputDeltas[5], closeTo(25.0, 1e-5));
    });

    test('handles 0 nodes edge case', () {
      final nodeStockpiles = Float32List(0);
      final componentLabels = Int32List(0);
      final int nodeCount = 0;

      final componentTotals = Float32List(1);
      final componentNodeCounts = Int32List(1);
      final componentAverages = Float32List(1);
      final outputDeltas = Float32List(0);

      // Initially set some garbage values to ensure they are zeroed out
      componentTotals[0] = 99.0;
      componentNodeCounts[0] = 99;
      componentAverages[0] = 99.0;

      StockpileBalanceCalculator.computeAverages(
        nodeStockpiles,
        componentLabels,
        nodeCount,
        componentTotals,
        componentNodeCounts,
        componentAverages,
      );

      expect(componentTotals[0], 0.0);
      expect(componentNodeCounts[0], 0);
      expect(componentAverages[0], 0.0);

      StockpileBalanceCalculator.computeDeficitsAndSurpluses(
        nodeStockpiles,
        componentLabels,
        componentAverages,
        nodeCount,
        outputDeltas,
      );

      expect(outputDeltas.length, 0);
    });

    test('handles uniform stockpiles', () {
      final nodeStockpiles = Float32List.fromList([50.0, 50.0, 50.0]);
      final componentLabels = Int32List.fromList([0, 0, 0]);
      final int nodeCount = 3;

      final componentTotals = Float32List(1);
      final componentNodeCounts = Int32List(1);
      final componentAverages = Float32List(1);
      final outputDeltas = Float32List(nodeCount);

      StockpileBalanceCalculator.computeAverages(
        nodeStockpiles,
        componentLabels,
        nodeCount,
        componentTotals,
        componentNodeCounts,
        componentAverages,
      );

      expect(componentAverages[0], 50.0);

      StockpileBalanceCalculator.computeDeficitsAndSurpluses(
        nodeStockpiles,
        componentLabels,
        componentAverages,
        nodeCount,
        outputDeltas,
      );

      expect(outputDeltas[0], closeTo(0.0, 1e-5));
      expect(outputDeltas[1], closeTo(0.0, 1e-5));
      expect(outputDeltas[2], closeTo(0.0, 1e-5));
    });

    test('handles highly skewed stockpiles', () {
      final nodeStockpiles = Float32List.fromList([1000.0, 0.0, 0.0, 0.0]);
      final componentLabels = Int32List.fromList([0, 0, 0, 0]);
      final int nodeCount = 4;

      final componentTotals = Float32List(1);
      final componentNodeCounts = Int32List(1);
      final componentAverages = Float32List(1);
      final outputDeltas = Float32List(nodeCount);

      StockpileBalanceCalculator.computeAverages(
        nodeStockpiles,
        componentLabels,
        nodeCount,
        componentTotals,
        componentNodeCounts,
        componentAverages,
      );

      expect(componentAverages[0], 250.0);

      StockpileBalanceCalculator.computeDeficitsAndSurpluses(
        nodeStockpiles,
        componentLabels,
        componentAverages,
        nodeCount,
        outputDeltas,
      );

      expect(outputDeltas[0], closeTo(750.0, 1e-5)); // Surplus
      expect(outputDeltas[1], closeTo(-250.0, 1e-5)); // Deficit
      expect(outputDeltas[2], closeTo(-250.0, 1e-5)); // Deficit
      expect(outputDeltas[3], closeTo(-250.0, 1e-5)); // Deficit
    });

    test('handles empty components correctly (zero division safety)', () {
      final nodeStockpiles = Float32List.fromList([10.0, 20.0]);
      final componentLabels = Int32List.fromList([
        0,
        0,
      ]); // Component 1 is empty
      final int nodeCount = 2;

      final componentTotals = Float32List(2);
      final componentNodeCounts = Int32List(2);
      final componentAverages = Float32List(2);
      final outputDeltas = Float32List(nodeCount);

      // Pre-fill with garbage
      componentAverages[1] = 99.9;

      StockpileBalanceCalculator.computeAverages(
        nodeStockpiles,
        componentLabels,
        nodeCount,
        componentTotals,
        componentNodeCounts,
        componentAverages,
      );

      // Component 0: Avg 15
      expect(componentAverages[0], 15.0);

      // Component 1: Empty, should be 0 safely
      expect(componentNodeCounts[1], 0);
      expect(componentTotals[1], 0.0);
      expect(componentAverages[1], 0.0); // Safe fallback to 0.0

      StockpileBalanceCalculator.computeDeficitsAndSurpluses(
        nodeStockpiles,
        componentLabels,
        componentAverages,
        nodeCount,
        outputDeltas,
      );

      expect(outputDeltas[0], closeTo(-5.0, 1e-5));
      expect(outputDeltas[1], closeTo(5.0, 1e-5));
    });
  });
}
