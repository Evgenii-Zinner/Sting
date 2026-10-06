import 'dart:typed_data';

/// High-performance, zero-allocation computational math utility for calculating
/// network stockpile balances across connected components.
class StockpileBalanceCalculator {
  /// Computes in O(N) single pass the total and average stockpile per connected component.
  ///
  /// - [nodeStockpiles]: The current stockpile amount for each node.
  /// - [componentLabels]: The connected component ID (0-based) for each node.
  /// - [nodeCount]: The number of nodes to process (up to nodeCount).
  /// - [componentTotals]: Scratch buffer for accumulated totals per component. Must be zeroed out by caller or this method.
  /// - [componentNodeCounts]: Scratch buffer for counting nodes per component. Must be zeroed out by caller or this method.
  /// - [componentAverages]: Output buffer for calculated averages per component.
  static void computeAverages(
    Float32List nodeStockpiles,
    Int32List componentLabels,
    int nodeCount,
    Float32List componentTotals,
    Int32List componentNodeCounts,
    Float32List componentAverages,
  ) {
    // 1. Zero out the accumulation buffers
    for (int i = 0; i < componentTotals.length; i++) {
      componentTotals[i] = 0.0;
      componentNodeCounts[i] = 0;
    }

    // 2. Accumulate totals and counts in a single O(N) pass
    for (int i = 0; i < nodeCount; i++) {
      final int compId = componentLabels[i];
      componentTotals[compId] += nodeStockpiles[i];
      componentNodeCounts[compId] += 1;
    }

    // 3. Compute averages
    for (int i = 0; i < componentAverages.length; i++) {
      final int count = componentNodeCounts[i];
      if (count > 0) {
        componentAverages[i] = componentTotals[i] / count;
      } else {
        componentAverages[i] = 0.0;
      }
    }
  }

  /// Computes the per-node deficit or surplus based on the component average.
  ///
  /// - [nodeStockpiles]: The current stockpile amount for each node.
  /// - [componentLabels]: The connected component ID (0-based) for each node.
  /// - [componentAverages]: The pre-calculated average stockpile for each component.
  /// - [nodeCount]: The number of nodes to process.
  /// - [outputDeltas]: Output buffer where value = current - targetAverage.
  ///   - Positive delta = surplus (available for hauler to take).
  ///   - Negative delta = deficit (needs supply from hauler).
  static void computeDeficitsAndSurpluses(
    Float32List nodeStockpiles,
    Int32List componentLabels,
    Float32List componentAverages,
    int nodeCount,
    Float32List outputDeltas,
  ) {
    for (int i = 0; i < nodeCount; i++) {
      final int compId = componentLabels[i];
      final double average = componentAverages[compId];
      outputDeltas[i] = nodeStockpiles[i] - average;
    }
  }
}
