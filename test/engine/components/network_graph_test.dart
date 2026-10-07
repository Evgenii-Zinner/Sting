import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/engine/components/network_graph.dart';

void main() {
  group('NetworkGraph Component', () {
    test('Initialization sets correct bounds', () {
      final graph = NetworkGraph.create(maxNodes: 10, maxEdges: 15);
      expect(graph.maxNodes, 10);
      expect(graph.maxEdges, 15);
      expect(graph.nodeCount, 0);
      expect(graph.edgeCount, 0);
    });

    test('Add node increments count and sets ID', () {
      final graph = NetworkGraph.create(maxNodes: 5, maxEdges: 5);
      int n0 = graph.addNode();
      int n1 = graph.addNode();
      expect(n0, 0);
      expect(n1, 1);
      expect(graph.nodeCount, 2);

      // Attempting to exceed maxNodes
      graph.addNode();
      graph.addNode();
      graph.addNode();
      int nFail = graph.addNode();
      expect(nFail, -1);
      expect(graph.nodeCount, 5);
    });

    test('Add edge increments count and validates nodes', () {
      final graph = NetworkGraph.create(maxNodes: 5, maxEdges: 5);
      graph.addNode();
      graph.addNode();

      bool s1 = graph.addEdge(0, 1);
      expect(s1, true);
      expect(graph.edgeCount, 1);

      // Invalid node indices
      bool s2 = graph.addEdge(0, 2);
      expect(s2, false);
      expect(graph.edgeCount, 1);
    });

    test('Clear resets counts', () {
      final graph = NetworkGraph.create(maxNodes: 5, maxEdges: 5);
      graph.addNode();
      graph.addNode();
      graph.addEdge(0, 1);

      graph.clear();
      expect(graph.nodeCount, 0);
      expect(graph.edgeCount, 0);
    });

    test('Partition correctly identifies connected components', () {
      final graph = NetworkGraph.create(maxNodes: 10, maxEdges: 10);
      for (int i = 0; i < 6; i++) {
        graph.addNode();
      }
      // Sub-graph 1: 0-1-2
      graph.addEdge(0, 1);
      graph.addEdge(1, 2);

      // Sub-graph 2: 3-4
      graph.addEdge(3, 4);

      // Node 5 is isolated

      Int32List scratchParent = Int32List(10);
      Int32List scratchRank = Int32List(10);

      graph.partition(scratchParent, scratchRank);

      int c0 = graph.getComponentId(0);
      int c1 = graph.getComponentId(1);
      int c2 = graph.getComponentId(2);

      int c3 = graph.getComponentId(3);
      int c4 = graph.getComponentId(4);

      int c5 = graph.getComponentId(5);

      expect(c0, c1);
      expect(c1, c2);

      expect(c3, c4);

      expect(c0, isNot(c3));
      expect(c0, isNot(c5));
      expect(c3, isNot(c5));
    });
  });
}
