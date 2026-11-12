import 'dart:typed_data';

/// A zero-allocation indexed MinHeap priority queue backed by contiguous typed arrays.
///
/// Designed for A* pathfinding and priority graph searches where node priorities ([fScore])
/// are updated frequently via [decreaseKey] without allocating wrapper objects on the heap.
class IndexedMinHeap {
  /// The dense array of element indices stored in the heap.
  final Int32List data;

  /// External array of priorities (lower score = higher priority).
  final Float32List fScore;

  /// Inverted index mapping `node -> position in data array` for O(1) lookup during [decreaseKey].
  final Int32List indices;

  /// The current number of active elements in the heap.
  int size = 0;

  /// Creates a new [IndexedMinHeap] with the specified [capacity] and backing priority array [fScore].
  IndexedMinHeap(int capacity, this.fScore)
      : data = Int32List(capacity),
        indices = Int32List(capacity) {
    indices.fillRange(0, capacity, -1);
  }

  /// Clears the heap and resets all tracked indices in O(size) time.
  void clear() {
    for (int i = 0; i < size; i++) {
      indices[data[i]] = -1;
    }
    size = 0;
  }

  /// Returns `true` if the heap contains no elements.
  bool get isEmpty => size == 0;

  /// Pushes a new [node] into the heap and restores the min-heap invariant.
  void push(int node) {
    int i = size++;
    while (i > 0) {
      final int parent = (i - 1) >> 1;
      final int pNode = data[parent];
      if (fScore[pNode] <= fScore[node]) break;
      data[i] = pNode;
      indices[pNode] = i;
      i = parent;
    }
    data[i] = node;
    indices[node] = i;
  }

  /// Pops the node with the minimum score from the heap.
  ///
  /// Returns `-1` if the heap is empty.
  int pop() {
    if (size == 0) return -1;
    final int root = data[0];
    indices[root] = -1;
    size--;
    if (size > 0) {
      final int lastNode = data[size];
      int i = 0;
      while (true) {
        final int left = (i << 1) + 1;
        final int right = left + 1;
        if (left >= size) break;

        int smallest = left;
        if (right < size && fScore[data[right]] < fScore[data[left]]) {
          smallest = right;
        }

        final int sNode = data[smallest];
        if (fScore[lastNode] <= fScore[sNode]) break;
        data[i] = sNode;
        indices[sNode] = i;
        i = smallest;
      }
      data[i] = lastNode;
      indices[lastNode] = i;
    }
    return root;
  }

  /// Re-heaps a [node] upward after its priority in [fScore] has been decreased.
  void decreaseKey(int node) {
    int i = indices[node];
    if (i == -1) return; // Not in heap

    while (i > 0) {
      final int parent = (i - 1) >> 1;
      final int pNode = data[parent];
      if (fScore[pNode] <= fScore[node]) break;
      data[i] = pNode;
      indices[pNode] = i;
      i = parent;
    }
    data[i] = node;
    indices[node] = i;
  }
}
