import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/engine/components/network_graph.dart';
import '../../../lib/engine/systems/collective_resource_pool_system.dart';

void main() {
  group('CollectiveResourcePoolSystem', () {
    test('Calculates effective levels correctly for single component', () {
      final graph = NetworkGraph.create(maxNodes: 5, maxEdges: 5);
      for (int i = 0; i < 3; i++) {
        graph.addNode();
      }
      // Fully connected 0-1-2
      graph.addEdge(0, 1);
      graph.addEdge(1, 2);

      final injections = Float32List(5);
      final losses = Float32List(5);
      final outLevels = Float32List(5);

      final scratchSums = Float32List(5);
      final scratchCounts = Int32List(5);
      final scratchParent = Int32List(5);
      final scratchRank = Int32List(5);

      // Net logic:
      // Node 0: inj 10, loss 2  -> net 8
      // Node 1: inj 5,  loss 5  -> net 0
      // Node 2: inj 0,  loss 2  -> net -2
      // Total net = 8 + 0 - 2 = 6
      // Nodes count = 3
      // Effective level = 6 / 3 = 2.0

      injections[0] = 10.0;
      losses[0] = 2.0;

      injections[1] = 5.0;
      losses[1] = 5.0;

      injections[2] = 0.0;
      losses[2] = 2.0;

      final system = CollectiveResourcePoolSystem();
      system.solve(
        graph: graph,
        injections: injections,
        losses: losses,
        outEffectiveLevels: outLevels,
        scratchComponentSums: scratchSums,
        scratchComponentCounts: scratchCounts,
        partitionGraph: true,
        scratchParent: scratchParent,
        scratchRank: scratchRank,
      );

      expect(outLevels[0], closeTo(2.0, 0.001));
      expect(outLevels[1], closeTo(2.0, 0.001));
      expect(outLevels[2], closeTo(2.0, 0.001));
      // Unused nodes stay 0
      expect(outLevels[3], 0.0);
      expect(outLevels[4], 0.0);
    });

    test('Disjoint networks have independent effective levels', () {
      final graph = NetworkGraph.create(maxNodes: 5, maxEdges: 5);
      for (int i = 0; i < 4; i++) {
        graph.addNode();
      }
      // Sub-graph A: 0-1
      graph.addEdge(0, 1);
      // Sub-graph B: 2-3
      graph.addEdge(2, 3);

      final injections = Float32List(5);
      final losses = Float32List(5);
      final outLevels = Float32List(5);

      final scratchSums = Float32List(5);
      final scratchCounts = Int32List(5);
      final scratchParent = Int32List(5);
      final scratchRank = Int32List(5);

      // Network A net = 10 + 0 - (2 + 2) = 6. Nodes = 2. Effective = 3.0
      injections[0] = 10.0;
      losses[0] = 2.0;
      injections[1] = 0.0;
      losses[1] = 2.0;

      // Network B net = 20 + 0 - (5 + 5) = 10. Nodes = 2. Effective = 5.0
      injections[2] = 20.0;
      losses[2] = 5.0;
      injections[3] = 0.0;
      losses[3] = 5.0;

      final system = CollectiveResourcePoolSystem();
      system.solve(
        graph: graph,
        injections: injections,
        losses: losses,
        outEffectiveLevels: outLevels,
        scratchComponentSums: scratchSums,
        scratchComponentCounts: scratchCounts,
        partitionGraph: true,
        scratchParent: scratchParent,
        scratchRank: scratchRank,
      );

      expect(outLevels[0], closeTo(3.0, 0.001));
      expect(outLevels[1], closeTo(3.0, 0.001));

      expect(outLevels[2], closeTo(5.0, 0.001));
      expect(outLevels[3], closeTo(5.0, 0.001));
    });

    test('Negative net total clamps effective level to 0', () {
      final graph = NetworkGraph.create(maxNodes: 5, maxEdges: 5);
      for (int i = 0; i < 2; i++) {
        graph.addNode();
      }
      graph.addEdge(0, 1);

      final injections = Float32List(5);
      final losses = Float32List(5);
      final outLevels = Float32List(5);

      final scratchSums = Float32List(5);
      final scratchCounts = Int32List(5);
      final scratchParent = Int32List(5);
      final scratchRank = Int32List(5);

      // Network net = 5 - 20 = -15.
      injections[0] = 5.0;
      losses[0] = 10.0;
      injections[1] = 0.0;
      losses[1] = 10.0;

      final system = CollectiveResourcePoolSystem();
      system.solve(
        graph: graph,
        injections: injections,
        losses: losses,
        outEffectiveLevels: outLevels,
        scratchComponentSums: scratchSums,
        scratchComponentCounts: scratchCounts,
        partitionGraph: true,
        scratchParent: scratchParent,
        scratchRank: scratchRank,
      );

      expect(outLevels[0], 0.0);
      expect(outLevels[1], 0.0);
    });

    test('Throws ArgumentError if partitionGraph is true but scratch buffers are missing', () {
      final graph = NetworkGraph.create(maxNodes: 5, maxEdges: 5);
      final injections = Float32List(5);
      final losses = Float32List(5);
      final outLevels = Float32List(5);

      final scratchSums = Float32List(5);
      final scratchCounts = Int32List(5);

      final system = CollectiveResourcePoolSystem();

      expect(
        () => system.solve(
          graph: graph,
          injections: injections,
          losses: losses,
          outEffectiveLevels: outLevels,
          scratchComponentSums: scratchSums,
          scratchComponentCounts: scratchCounts,
          partitionGraph: true,
          // Missing scratchParent/scratchRank
        ),
        throwsArgumentError,
      );
    });
  });
}
