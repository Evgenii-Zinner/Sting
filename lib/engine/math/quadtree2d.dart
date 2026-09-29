import 'dart:typed_data';

/// A zero-allocation 2D Quadtree spatial partitioning index.
///
/// Uses parallel flat typed arrays for nodes and elements to avoid per-frame
/// Garbage Collection allocations during physics or culling phases.
class QuadTree2D {
  final int maxEntitiesPerNode;
  final int maxDepth;
  final int maxNodes;
  final int maxElements;

  int _nodeCount = 0;
  int _elementCount = 0;

  // Node pool
  final Float32List _nodeBounds; // minX, minY, maxX, maxY (4 per node)
  final Int32List _nodeChildren; // NW, NE, SW, SE (4 per node)
  final Int32List _nodeFirstElement; // Head of element linked list (1 per node)
  final Int32List _nodeElementCount; // Elements directly in this node (1 per node)

  // Element pool
  final Int32List _elementEntity; // Entity ID (1 per element)
  final Float32List _elementBounds; // minX, minY, maxX, maxY (4 per element)
  final Int32List _elementNext; // Next element index in the node (1 per element)

  QuadTree2D(
    double rootMinX,
    double rootMinY,
    double rootMaxX,
    double rootMaxY, {
    this.maxEntitiesPerNode = 4,
    this.maxDepth = 8,
    this.maxNodes = 10000,
    this.maxElements = 10000,
  })  : _nodeBounds = Float32List(maxNodes * 4),
        _nodeChildren = Int32List(maxNodes * 4),
        _nodeFirstElement = Int32List(maxNodes),
        _nodeElementCount = Int32List(maxNodes),
        _elementEntity = Int32List(maxElements),
        _elementBounds = Float32List(maxElements * 4),
        _elementNext = Int32List(maxElements) {
    _allocNode(rootMinX, rootMinY, rootMaxX, rootMaxY);
  }

  /// Resets the quadtree in O(1) time without reallocating buffers.
  void clear() {
    if (_nodeCount > 0) {
      _nodeCount = 1; // Preserve root node
      _elementCount = 0;

      // Reset root state
      _nodeChildren[0] = -1;
      _nodeChildren[1] = -1;
      _nodeChildren[2] = -1;
      _nodeChildren[3] = -1;

      _nodeFirstElement[0] = -1;
      _nodeElementCount[0] = 0;
    }
  }

  /// Inserts an entity into the quadtree using its AABB.
  void insert(int entity, double minX, double minY, double maxX, double maxY) {
    if (_nodeCount == 0 || _elementCount >= maxElements) return;
    _insertAt(0, entity, minX, minY, maxX, maxY, 0);
  }

  void _insertAt(
    int nodeIdx,
    int entity,
    double minX,
    double minY,
    double maxX,
    double maxY,
    int depth,
  ) {
    // If this node has children, attempt to push the entity down to a child that fully contains it.
    if (_hasChildren(nodeIdx)) {
      int childIdx = _findContainingChild(nodeIdx, minX, minY, maxX, maxY);
      if (childIdx != -1) {
        _insertAt(childIdx, entity, minX, minY, maxX, maxY, depth + 1);
        return;
      }
    }

    // Allocate an element
    int elementIdx = _allocElement(entity, minX, minY, maxX, maxY);
    if (elementIdx == -1) return;

    _addElementToNode(nodeIdx, elementIdx);

    // Subdivide if this node is a leaf and has exceeded its capacity
    if (!_hasChildren(nodeIdx) &&
        _nodeElementCount[nodeIdx] > maxEntitiesPerNode &&
        depth < maxDepth) {
      _subdivide(nodeIdx);
      _redistribute(nodeIdx);
    }
  }

  /// Queries the quadtree for entities overlapping the specified AABB.
  /// Returns the number of entities found, which is capped at [outEntities.length].
  int queryAABB(
    double minX,
    double minY,
    double maxX,
    double maxY,
    Int32List outEntities,
  ) {
    if (_nodeCount == 0) return 0;
    return _queryAABBNode(0, minX, minY, maxX, maxY, outEntities, 0);
  }

  int _queryAABBNode(
    int nodeIdx,
    double minX,
    double minY,
    double maxX,
    double maxY,
    Int32List outEntities,
    int outCount,
  ) {
    if (outCount >= outEntities.length) return outCount;

    int bIdx = nodeIdx * 4;
    double nMinX = _nodeBounds[bIdx];
    double nMinY = _nodeBounds[bIdx + 1];
    double nMaxX = _nodeBounds[bIdx + 2];
    double nMaxY = _nodeBounds[bIdx + 3];

    // Node AABB completely outside query AABB
    if (minX > nMaxX || maxX < nMinX || minY > nMaxY || maxY < nMinY) {
      return outCount;
    }

    // Check elements in this node
    int curr = _nodeFirstElement[nodeIdx];
    while (curr != -1) {
      int eBIdx = curr * 4;
      double eMinX = _elementBounds[eBIdx];
      double eMinY = _elementBounds[eBIdx + 1];
      double eMaxX = _elementBounds[eBIdx + 2];
      double eMaxY = _elementBounds[eBIdx + 3];

      // If AABBs overlap
      if (!(minX > eMaxX || maxX < eMinX || minY > eMaxY || maxY < eMinY)) {
        if (outCount < outEntities.length) {
          outEntities[outCount++] = _elementEntity[curr];
        } else {
          return outCount;
        }
      }

      curr = _elementNext[curr];
    }

    // Recurse into children
    if (_hasChildren(nodeIdx)) {
      for (int i = 0; i < 4; i++) {
        int childIdx = _nodeChildren[nodeIdx * 4 + i];
        if (childIdx != -1) {
          outCount = _queryAABBNode(
              childIdx, minX, minY, maxX, maxY, outEntities, outCount);
          if (outCount >= outEntities.length) return outCount;
        }
      }
    }

    return outCount;
  }

  int _allocNode(double minX, double minY, double maxX, double maxY) {
    if (_nodeCount >= maxNodes) return -1;
    int idx = _nodeCount++;

    int bIdx = idx * 4;
    _nodeBounds[bIdx] = minX;
    _nodeBounds[bIdx + 1] = minY;
    _nodeBounds[bIdx + 2] = maxX;
    _nodeBounds[bIdx + 3] = maxY;

    int cIdx = idx * 4;
    _nodeChildren[cIdx] = -1;
    _nodeChildren[cIdx + 1] = -1;
    _nodeChildren[cIdx + 2] = -1;
    _nodeChildren[cIdx + 3] = -1;

    _nodeFirstElement[idx] = -1;
    _nodeElementCount[idx] = 0;

    return idx;
  }

  int _allocElement(
      int entity, double minX, double minY, double maxX, double maxY) {
    if (_elementCount >= maxElements) return -1;
    int idx = _elementCount++;

    _elementEntity[idx] = entity;

    int bIdx = idx * 4;
    _elementBounds[bIdx] = minX;
    _elementBounds[bIdx + 1] = minY;
    _elementBounds[bIdx + 2] = maxX;
    _elementBounds[bIdx + 3] = maxY;

    _elementNext[idx] = -1;

    return idx;
  }

  void _addElementToNode(int nodeIdx, int elementIdx) {
    _elementNext[elementIdx] = _nodeFirstElement[nodeIdx];
    _nodeFirstElement[nodeIdx] = elementIdx;
    _nodeElementCount[nodeIdx]++;
  }

  void _removeElementFromNode(int nodeIdx, int elementIdx, int prevElementIdx) {
    if (prevElementIdx == -1) {
      _nodeFirstElement[nodeIdx] = _elementNext[elementIdx];
    } else {
      _elementNext[prevElementIdx] = _elementNext[elementIdx];
    }
    _nodeElementCount[nodeIdx]--;
  }

  bool _hasChildren(int nodeIdx) {
    return _nodeChildren[nodeIdx * 4] != -1;
  }

  int _findContainingChild(
      int nodeIdx, double minX, double minY, double maxX, double maxY) {
    for (int i = 0; i < 4; i++) {
      int childIdx = _nodeChildren[nodeIdx * 4 + i];
      if (childIdx != -1) {
        int bIdx = childIdx * 4;
        double cMinX = _nodeBounds[bIdx];
        double cMinY = _nodeBounds[bIdx + 1];
        double cMaxX = _nodeBounds[bIdx + 2];
        double cMaxY = _nodeBounds[bIdx + 3];

        if (minX >= cMinX && minY >= cMinY && maxX <= cMaxX && maxY <= cMaxY) {
          return childIdx;
        }
      }
    }
    return -1;
  }

  void _subdivide(int nodeIdx) {
    int bIdx = nodeIdx * 4;
    double minX = _nodeBounds[bIdx];
    double minY = _nodeBounds[bIdx + 1];
    double maxX = _nodeBounds[bIdx + 2];
    double maxY = _nodeBounds[bIdx + 3];

    double midX = minX + (maxX - minX) / 2;
    double midY = minY + (maxY - minY) / 2;

    int cIdx = nodeIdx * 4;
    _nodeChildren[cIdx] = _allocNode(minX, minY, midX, midY); // NW
    _nodeChildren[cIdx + 1] = _allocNode(midX, minY, maxX, midY); // NE
    _nodeChildren[cIdx + 2] = _allocNode(minX, midY, midX, maxY); // SW
    _nodeChildren[cIdx + 3] = _allocNode(midX, midY, maxX, maxY); // SE
  }

  void _redistribute(int nodeIdx) {
    int curr = _nodeFirstElement[nodeIdx];
    int prev = -1;

    while (curr != -1) {
      int next = _elementNext[curr];

      int bIdx = curr * 4;
      double eMinX = _elementBounds[bIdx];
      double eMinY = _elementBounds[bIdx + 1];
      double eMaxX = _elementBounds[bIdx + 2];
      double eMaxY = _elementBounds[bIdx + 3];

      int childIdx = _findContainingChild(nodeIdx, eMinX, eMinY, eMaxX, eMaxY);
      if (childIdx != -1) {
        _removeElementFromNode(nodeIdx, curr, prev);
        _addElementToNode(childIdx, curr);
        // prev remains the same because curr was extracted from the list
      } else {
        prev = curr;
      }

      curr = next;
    }
  }

  // Accessors for testing
  int get nodeCount => _nodeCount;
  int get elementCount => _elementCount;
}
