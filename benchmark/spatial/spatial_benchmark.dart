import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:sting/engine/math/quadtree.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';
import 'dart:math';
import 'dart:typed_data';

class SpatialHashGridQueryBenchmark extends BenchmarkBase {
  late SpatialHashGrid grid;
  final int entityCount;
  int _found = 0;

  SpatialHashGridQueryBenchmark({this.entityCount = 10000}) : super('SpatialHashGridQuery($entityCount)');

  @override
  void run() {
    _found = 0;
    // Query a 100x100 area in the middle of the 1000x1000 space
    grid.queryAABB(450, 450, 100, 100, (int entity) {
      _found++;
      return true;
    });
    // ignore: avoid_print
    if (_found < 0) print(_found);
  }

  @override
  void setup() {
    // 1000x1000 map, 50x50 cells (cell size 20)
    grid = SpatialHashGrid(20, 50 * 50);
    final rand = Random(42);
    for (int i = 0; i < entityCount; i++) {
      grid.insert(i, rand.nextDouble() * 1000, rand.nextDouble() * 1000);
    }
  }
}

class QuadtreeForceBenchmark extends BenchmarkBase {
  late BarnesHutTree tree;
  final int entityCount;
  final Float32List force = Float32List(2);

  QuadtreeForceBenchmark({this.entityCount = 10000}) : super('QuadTreeForceAccumulation($entityCount)');

  @override
  void run() {
    force[0] = 0;
    force[1] = 0;
    // Calculate force for entity at center
    tree.accumulateForce(0, 500, 500, 0.5, 1.0, force);
    // ignore: avoid_print
    if (force[0] < -1000000) print(force[0]);
  }

  @override
  void setup() {
    tree = BarnesHutTree(maxNodes: entityCount * 8);
    tree.initRoot(0, 0, 1000, 1000);
    final rand = Random(42);
    for (int i = 0; i < entityCount; i++) {
      tree.insert(i, rand.nextDouble() * 1000, rand.nextDouble() * 1000, 1.0);
    }
  }
}

void main() {
  SpatialHashGridQueryBenchmark().report();
  QuadtreeForceBenchmark().report();
}
