import 'dart:io';

import 'ecs/query_benchmark.dart';
import 'spatial/spatial_benchmark.dart';
import 'systems/system_benchmark.dart';
import 'ecs/entity_manager_benchmark.dart';

class BenchmarkResult {
  final String name;
  final double measured;
  final double budget;
  BenchmarkResult(this.name, this.measured, this.budget);
}

void main() {
  final results = <BenchmarkResult>[];

  results.add(BenchmarkResult('Query1Iteration(10000)', Query1Benchmark().measure(), 1200));
  results.add(BenchmarkResult('Query2Iteration(10000)', Query2Benchmark().measure(), 1500));
  results.add(BenchmarkResult('Query3Iteration(10000)', Query3Benchmark().measure(), 2000));

  results.add(BenchmarkResult('SpatialHashGridQuery(10000)', SpatialHashGridQueryBenchmark().measure(), 150));
  results.add(BenchmarkResult('QuadTreeForceAccumulation(10000)', QuadtreeForceBenchmark().measure(), 150));

  results.add(BenchmarkResult('SystemDispatch(100)', SystemDispatchBenchmark().measure(), 100));

  final count = 10000;

  results.add(BenchmarkResult('SwarmSpawning($count)', EntityManagerBenchmark.measureSpawning(count), 3500));
  results.add(BenchmarkResult('ComponentAddition($count)', EntityManagerBenchmark.measureComponentAddition(count), 5000));
  results.add(BenchmarkResult('ComponentRemoval($count)', EntityManagerBenchmark.measureComponentRemoval(count), 5000));

  // ignore: avoid_print
  print('| Name | Measured Time (us) | Budget Limit (us) | Status |');
  // ignore: avoid_print
  print('|---|---|---|---|');
  bool regression = false;
  for (final r in results) {
    final status = r.measured <= r.budget ? 'PASS' : 'REGRESSION';
    if (status == 'REGRESSION') {
      regression = true;
    }
    // ignore: avoid_print
    print('| ${r.name} | ${r.measured.toStringAsFixed(1)} | ${r.budget.toStringAsFixed(1)} | $status |');
  }

  if (regression) {
    // ignore: avoid_print
    print('\nError: One or more benchmarks exceeded their budget limits.');
    exit(1);
  }
}
