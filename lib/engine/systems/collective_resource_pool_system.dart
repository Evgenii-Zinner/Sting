import 'dart:typed_data';
import '../components/network_graph.dart';

/// A generic solver system for collective resource pools (power grids, fluid pipelines, heat magistrals).
/// Computes per-component effective values with zero heap allocations per frame.
class CollectiveResourcePoolSystem {
  /// Solves the network graph by summing injections and losses for each connected sub-graph.
  ///
  /// Inputs:
  /// - [graph]: The topological network graph. Must have been partitioned recently (or call [partitionGraph] = true).
  /// - [injections]: `Float32List` of length `>= graph.maxNodes`. The resource injected at each node index.
  /// - [losses]: `Float32List` of length `>= graph.maxNodes`. The dissipation/maintenance loss at each node index.
  ///
  /// Outputs:
  /// - [outEffectiveLevels]: `Float32List` where the result for each node will be written.
  ///
  /// Scratch Buffers:
  /// - [scratchComponentSums]: `Float32List` of length `>= graph.maxNodes`.
  /// - [scratchComponentCounts]: `Int32List` of length `>= graph.maxNodes`.
  /// - [scratchParent]: (Optional) `Int32List` for partitioning.
  /// - [scratchRank]: (Optional) `Int32List` for partitioning.
  void solve({
    required NetworkGraph graph,
    required Float32List injections,
    required Float32List losses,
    required Float32List outEffectiveLevels,
    required Float32List scratchComponentSums,
    required Int32List scratchComponentCounts,
    bool partitionGraph = false,
    Int32List? scratchParent,
    Int32List? scratchRank,
  }) {
    int nodeCount = graph.nodeCount;

    if (partitionGraph) {
      if (scratchParent == null || scratchRank == null) {
        throw ArgumentError("scratchParent and scratchRank must be provided if partitionGraph is true.");
      }
      graph.partition(scratchParent, scratchRank);
    }

    // 1. Reset scratch buffers for active components
    // We only need to clear up to nodeCount since component IDs are bounded by nodeCount.
    for (int i = 0; i < nodeCount; i++) {
      scratchComponentSums[i] = 0.0;
      scratchComponentCounts[i] = 0;
    }

    // 2. Aggregate injections and losses per component
    for (int i = 0; i < nodeCount; i++) {
      int componentId = graph.getComponentId(i);
      if (componentId != -1) {
        double net = injections[i] - losses[i];
        scratchComponentSums[componentId] += net;
        scratchComponentCounts[componentId]++;
      }
    }

    // 3. Compute per-node effective levels and distribute back
    for (int i = 0; i < nodeCount; i++) {
      int componentId = graph.getComponentId(i);
      if (componentId != -1) {
        int count = scratchComponentCounts[componentId];
        double totalSum = scratchComponentSums[componentId];

        if (count > 0) {
          // Calculate the uniform effective level distributed across the nodes.
          // If the net sum is negative (total losses > total injections), the pool level drops to 0 (or appropriately distributed deficit).
          // For generic resource pools, we clamp at 0 if the collective pool runs completely dry.
          double effective = totalSum / count;
          outEffectiveLevels[i] = effective < 0.0 ? 0.0 : effective;
        } else {
          outEffectiveLevels[i] = 0.0;
        }
      } else {
        outEffectiveLevels[i] = 0.0;
      }
    }
  }
}
