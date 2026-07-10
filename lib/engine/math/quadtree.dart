import 'dart:typed_data';
import 'dart:math';

/// A zero-allocation Quadtree for Barnes-Hut N-Body simulation.
class BarnesHutTree {
  final int maxNodes;
  final int maxDepth;
  final double softening;
  final double softeningSq;

  int _nodeCount = 0;

  // Node arrays
  final Float32List _nodeBounds; // x, y, width, height (4 floats per node)
  final Float32List _nodeMass; // mass (1 float per node)
  final Float32List _nodeCM; // cmX, cmY (2 floats per node)
  final Int32List _nodeChildren; // NW, NE, SW, SE (4 ints per node)
  final Int32List
      _nodeEntity; // entity id (1 int per node, -1 if none/internal)

  BarnesHutTree({this.maxNodes = 40000, this.maxDepth = 32, this.softening = 0.1})
      : softeningSq = softening * softening,
        _nodeBounds = Float32List(maxNodes * 4),
        _nodeMass = Float32List(maxNodes),
        _nodeCM = Float32List(maxNodes * 2),
        _nodeChildren = Int32List(maxNodes * 4),
        _nodeEntity = Int32List(maxNodes);

  void clear() {
    _nodeCount = 0;
  }

  /// Initializes the root node with the given bounds.
  void initRoot(double x, double y, double width, double height) {
    clear();
    _allocNode(x, y, width, height);
  }

  int _allocNode(double x, double y, double width, double height) {
    if (_nodeCount >= maxNodes) {
      return -1;
    }

    int index = _nodeCount++;

    int bIdx = index * 4;
    _nodeBounds[bIdx] = x;
    _nodeBounds[bIdx + 1] = y;
    _nodeBounds[bIdx + 2] = width;
    _nodeBounds[bIdx + 3] = height;

    _nodeMass[index] = 0.0;

    int cmIdx = index * 2;
    _nodeCM[cmIdx] = 0.0;
    _nodeCM[cmIdx + 1] = 0.0;

    int cIdx = index * 4;
    _nodeChildren[cIdx] = -1;
    _nodeChildren[cIdx + 1] = -1;
    _nodeChildren[cIdx + 2] = -1;
    _nodeChildren[cIdx + 3] = -1;

    _nodeEntity[index] = -1;

    return index;
  }

  /// Inserts a body into the tree.
  void insert(int entity, double x, double y, double mass) {
    if (_nodeCount == 0) return; // Root must be initialized
    _insertAt(0, entity, x, y, mass, 0);
  }

  void _insertAt(
      int nodeIdx, int entity, double x, double y, double mass, int depth) {
    if (nodeIdx == -1) return;
    // If empty leaf
    if (_nodeMass[nodeIdx] == 0.0) {
      _nodeEntity[nodeIdx] = entity;
      _nodeMass[nodeIdx] = mass;
      _nodeCM[nodeIdx * 2] = x;
      _nodeCM[nodeIdx * 2 + 1] = y;
      return;
    }

    // Update center of mass and total mass
    double currentMass = _nodeMass[nodeIdx];
    double newMass = currentMass + mass;
    double currentCMX = _nodeCM[nodeIdx * 2];
    double currentCMY = _nodeCM[nodeIdx * 2 + 1];

    _nodeCM[nodeIdx * 2] = (currentCMX * currentMass + x * mass) / newMass;
    _nodeCM[nodeIdx * 2 + 1] = (currentCMY * currentMass + y * mass) / newMass;
    _nodeMass[nodeIdx] = newMass;

    // If it was a leaf, we need to subdivide and move the existing entity
    if (_nodeEntity[nodeIdx] != -1) {
      // It's a leaf, move the existing entity
      int existingEntity = _nodeEntity[nodeIdx];

      // We don't store individual positions in nodes, but we know the leaf's CM is the entity's position!
      double ex =
          currentCMX; // using before update would be better, but we already updated it
      // Actually, since we updated CM, the new CM is a blend.
      // Wait, we need the *original* position of the existing entity to move it.
      // Since it was a leaf, its previous CM was EXACTLY the existing entity's position.
      // We MUST use the old CM!
      ex = currentCMX; // This is the old CM before we updated it?
      // Wait, we just overwrote `_nodeCM[nodeIdx * 2] = ...`!
      // currentCMX was captured BEFORE the overwrite.
      // So currentCMX is the exact old CM. Correct!
      double ey = currentCMY;

      _nodeEntity[nodeIdx] = -1; // It's now an internal node

      if (depth + 1 < maxDepth) {
        // Prevent infinite recursion for perfectly identical positions
        if ((ex - x).abs() < 1e-6 && (ey - y).abs() < 1e-6) {
          // Jitter one slightly to avoid stack overflow.
          ex += 0.001;
        }

        int qExisting = _getQuadrant(nodeIdx, ex, ey);
        int childIdxExisting = _getOrCreateChild(nodeIdx, qExisting);
        _insertAt(
            childIdxExisting, existingEntity, ex, ey, currentMass, depth + 1);
      }
    }

    // Now insert the new entity
    if (depth + 1 < maxDepth) {
      int qNew = _getQuadrant(nodeIdx, x, y);
      int childIdxNew = _getOrCreateChild(nodeIdx, qNew);
      _insertAt(childIdxNew, entity, x, y, mass, depth + 1);
    }
  }

  int _getQuadrant(int nodeIdx, double x, double y) {
    int bIdx = nodeIdx * 4;
    double nx = _nodeBounds[bIdx];
    double ny = _nodeBounds[bIdx + 1];
    double nw = _nodeBounds[bIdx + 2];
    double nh = _nodeBounds[bIdx + 3];

    double midX = nx + nw / 2;
    double midY = ny + nh / 2;

    // Quadrants:
    // 0: NW, 1: NE, 2: SW, 3: SE
    bool isEast = x >= midX;
    bool isSouth = y >= midY;

    if (!isSouth && !isEast) return 0; // NW
    if (!isSouth && isEast) return 1; // NE
    if (isSouth && !isEast) return 2; // SW
    return 3; // SE
  }

  int _getOrCreateChild(int nodeIdx, int quadrant) {
    if (nodeIdx == -1) return -1;
    int cIdx = nodeIdx * 4 + quadrant;
    if (_nodeChildren[cIdx] == -1) {
      // Create child
      int bIdx = nodeIdx * 4;
      double nx = _nodeBounds[bIdx];
      double ny = _nodeBounds[bIdx + 1];
      double nw = _nodeBounds[bIdx + 2];
      double nh = _nodeBounds[bIdx + 3];

      double cw = nw / 2;
      double ch = nh / 2;

      double cx = nx + (quadrant == 1 || quadrant == 3 ? cw : 0);
      double cy = ny + (quadrant >= 2 ? ch : 0);

      int newChild = _allocNode(cx, cy, cw, ch);
      _nodeChildren[cIdx] = newChild;
    }
    return _nodeChildren[cIdx];
  }

  /// Calculates the net gravitational force on a body at (x, y).
  /// [theta] is the Barnes-Hut threshold (typically 0.5).
  /// [g] is the gravitational constant.
  /// [outForce] is a Float32List of length 2 where the result is accumulated (adds to existing value).
  void accumulateForce(int entity, double x, double y, double theta, double g,
      Float32List outForce) {
    if (_nodeCount == 0) return;
    _accumulateForceRecursive(0, entity, x, y, theta, g, outForce);
  }

  void _accumulateForceRecursive(int nodeIdx, int entity, double x, double y,
      double theta, double g, Float32List outForce) {
    double mass = _nodeMass[nodeIdx];
    if (mass == 0.0) return;

    double cmX = _nodeCM[nodeIdx * 2];
    double cmY = _nodeCM[nodeIdx * 2 + 1];

    double dx = cmX - x;
    double dy = cmY - y;
    double distSq = dx * dx + dy * dy;

    // Softening parameter to avoid infinite force at zero distance
    distSq += softeningSq;

    double dist = sqrt(distSq);

    int bIdx = nodeIdx * 4;
    double nw = _nodeBounds[bIdx + 2]; // assuming square, w == h

    // If it's a leaf, or if (s / d < theta), treat as a single body
    if (_nodeEntity[nodeIdx] != -1 || (nw / dist) < theta) {
      if (_nodeEntity[nodeIdx] == entity) {
        return; // Don't attract self
      }

      double force = (g * mass) / distSq;
      outForce[0] += force * (dx / dist);
      outForce[1] += force * (dy / dist);
      return;
    }

    // Otherwise, sum forces from children
    for (int i = 0; i < 4; i++) {
      int childIdx = _nodeChildren[nodeIdx * 4 + i];
      if (childIdx != -1) {
        _accumulateForceRecursive(childIdx, entity, x, y, theta, g, outForce);
      }
    }
  }

  // Accessors for testing
  int get nodeCount => _nodeCount;
  double get totalMass => _nodeCount > 0 ? _nodeMass[0] : 0.0;
}
