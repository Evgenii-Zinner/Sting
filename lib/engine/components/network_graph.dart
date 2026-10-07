import 'dart:typed_data';

/// A generic flat graph data structure represented as an ECS component or data struct.
/// It uses a contiguous typed array (Int32List) to store nodes and adjacency edges.
/// Layout:
///   [0] = maxNodes
///   [1] = maxEdges
///   [2] = nodeCount
///   [3] = edgeCount
///   [4 ... 4+maxNodes-1] = node array (stores component ID per node)
///   [4+maxNodes ... 4+maxNodes+(maxEdges*2)-1] = edge array (pairs of node indices)
///   [scratch] = component size tracker or scratch buffer for partitioning
extension type NetworkGraph(Int32List data) {
  static const int _headerSize = 4;

  /// Creates a NetworkGraph capable of storing up to [maxNodes] and [maxEdges].
  /// The backing array is fully pre-allocated.
  NetworkGraph.create({required int maxNodes, required int maxEdges})
      : this(Int32List(_headerSize + maxNodes + (maxEdges * 2))
          ..[0] = maxNodes
          ..[1] = maxEdges
          ..[2] = 0
          ..[3] = 0);

  int get maxNodes => data[0];
  int get maxEdges => data[1];

  int get nodeCount => data[2];
  set nodeCount(int value) => data[2] = value;

  int get edgeCount => data[3];
  set edgeCount(int value) => data[3] = value;

  /// The starting offset of the nodes array in the backing Int32List.
  int get _nodesOffset => _headerSize;

  /// The starting offset of the edges array in the backing Int32List.
  int get _edgesOffset => _headerSize + maxNodes;

  /// Adds a node. In this simple representation, a node is just an index (0 to nodeCount - 1).
  /// Returns the assigned node index, or -1 if capacity is reached.
  int addNode() {
    int current = nodeCount;
    if (current >= maxNodes) {
      return -1;
    }
    // Initialize its component ID to itself
    data[_nodesOffset + current] = current;
    nodeCount = current + 1;
    return current;
  }

  /// Adds an undirected edge between [nodeA] and [nodeB].
  /// Returns true on success, false if capacity is reached or nodes are invalid.
  bool addEdge(int nodeA, int nodeB) {
    if (nodeA < 0 || nodeA >= nodeCount || nodeB < 0 || nodeB >= nodeCount) {
      return false;
    }
    int current = edgeCount;
    if (current >= maxEdges) {
      return false;
    }

    int edgeIdx = _edgesOffset + (current * 2);
    data[edgeIdx] = nodeA;
    data[edgeIdx + 1] = nodeB;

    edgeCount = current + 1;
    return true;
  }

  /// Clears the graph of all nodes and edges (O(1) operation).
  void clear() {
    nodeCount = 0;
    edgeCount = 0;
  }

  /// Finds the root of [node] using path compression.
  int _find(int node, Int32List parent) {
    int root = node;
    while (root != parent[root]) {
      // Path halving optimization
      parent[root] = parent[parent[root]];
      root = parent[root];
    }
    return root;
  }

  /// Merges the sets containing [nodeA] and [nodeB].
  void _union(int nodeA, int nodeB, Int32List parent, Int32List rank) {
    int rootA = _find(nodeA, parent);
    int rootB = _find(nodeB, parent);

    if (rootA != rootB) {
      if (rank[rootA] < rank[rootB]) {
        parent[rootA] = rootB;
      } else if (rank[rootA] > rank[rootB]) {
        parent[rootB] = rootA;
      } else {
        parent[rootB] = rootA;
        rank[rootA]++;
      }
    }
  }

  /// Partitions the graph into connected components using a Union-Find (Disjoint-Set) algorithm.
  /// Needs two scratch buffers of size >= maxNodes.
  /// After calling this, getComponentId(nodeIndex) will return the root ID of its connected sub-graph.
  void partition(Int32List scratchParent, Int32List scratchRank) {
    int nodes = nodeCount;
    // Initialize disjoint sets
    for (int i = 0; i < nodes; i++) {
      scratchParent[i] = i;
      scratchRank[i] = 0;
    }

    // Process all edges
    int edges = edgeCount;
    for (int i = 0; i < edges; i++) {
      int edgeIdx = _edgesOffset + (i * 2);
      int nodeA = data[edgeIdx];
      int nodeB = data[edgeIdx + 1];
      _union(nodeA, nodeB, scratchParent, scratchRank);
    }

    // Flatten and assign back to nodes array
    for (int i = 0; i < nodes; i++) {
      int rootId = _find(i, scratchParent);
      data[_nodesOffset + i] = rootId;
    }
  }

  /// Retrieves the component ID assigned to [nodeIndex].
  /// Requires `partition()` to have been called for up-to-date results.
  int getComponentId(int nodeIndex) {
    if (nodeIndex < 0 || nodeIndex >= nodeCount) {
      return -1;
    }
    return data[_nodesOffset + nodeIndex];
  }
}
