import 'package:flutter_test/flutter_test.dart';
import '../../benchmark/ecs/query_benchmark.dart';
import '../../benchmark/spatial/spatial_benchmark.dart';
import '../../benchmark/systems/system_benchmark.dart';
import '../../benchmark/ecs/entity_manager_benchmark.dart';

void main() {
  group('Performance Regression Limits', () {
    test('Query1Iteration is within budget', () {
      final benchmark = Query1Benchmark();
      final measured = benchmark.measure();
      // Test environment budgets. Generous headroom for shared CI runners.
      expect(measured, lessThanOrEqualTo(1200 * 2));
    });

    test('Query2Iteration is within budget', () {
      final benchmark = Query2Benchmark();
      final measured = benchmark.measure();
      expect(measured, lessThanOrEqualTo(1500 * 2));
    });

    test('Query3Iteration is within budget', () {
      final benchmark = Query3Benchmark();
      final measured = benchmark.measure();
      expect(measured, lessThanOrEqualTo(2000 * 2));
    });

    test('SpatialHashGridQuery is within budget', () {
      final benchmark = SpatialHashGridQueryBenchmark();
      final measured = benchmark.measure();
      expect(measured, lessThanOrEqualTo(150 * 2));
    });

    test('QuadTreeForceAccumulation is within budget', () {
      final benchmark = QuadtreeForceBenchmark();
      final measured = benchmark.measure();
      expect(measured, lessThanOrEqualTo(150 * 2));
    });

    test('SystemDispatch is within budget', () {
      final benchmark = SystemDispatchBenchmark();
      final measured = benchmark.measure();
      expect(measured, lessThanOrEqualTo(100 * 2));
    });

    test('SwarmSpawning is within budget', () {
      final count = 10000;
      final measured = EntityManagerBenchmark.measureSpawning(count);
      expect(measured, lessThanOrEqualTo(3500 * 2));
    });

    test('ComponentAddition is within budget', () {
      final count = 10000;
      final measured = EntityManagerBenchmark.measureComponentAddition(count);
      expect(measured, lessThanOrEqualTo(5000 * 2));
    });

    test('ComponentRemoval is within budget', () {
      final count = 10000;
      final measured = EntityManagerBenchmark.measureComponentRemoval(count);
      expect(measured, lessThanOrEqualTo(5000 * 2));
    });
  });
}
