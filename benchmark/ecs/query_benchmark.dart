import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';

class Query1Benchmark extends BenchmarkBase {
  late ComponentCaste<double> caste1;
  late Query1<double> query;
  final int count;
  double _sum = 0;

  Query1Benchmark({this.count = 10000}) : super('Query1Iteration($count)');

  @override
  void run() {
    _sum = 0;
    query.forEach((e, c1) {
      _sum += c1;
    });
    // ignore: avoid_print
    if (_sum < 0) print(_sum); // Prevent optimization
  }

  @override
  void setup() {
    caste1 = ComponentCaste<double>(count);
    query = Query1<double>(caste1);
    for (int i = 0; i < count; i++) {
      caste1.add(i, i.toDouble());
    }
  }
}

class Query2Benchmark extends BenchmarkBase {
  late ComponentCaste<double> caste1;
  late ComponentCaste<double> caste2;
  late Query2<double, double> query;
  final int count;
  double _sum = 0;

  Query2Benchmark({this.count = 10000}) : super('Query2Iteration($count)');

  @override
  void run() {
    _sum = 0;
    query.forEach((e, c1, c2) {
      _sum += c1 + c2;
    });
    // ignore: avoid_print
    if (_sum < 0) print(_sum); // Prevent optimization
  }

  @override
  void setup() {
    caste1 = ComponentCaste<double>(count);
    caste2 = ComponentCaste<double>(count);
    query = Query2<double, double>(caste1, caste2);
    for (int i = 0; i < count; i++) {
      caste1.add(i, i.toDouble());
      caste2.add(i, i.toDouble());
    }
  }
}

class Query3Benchmark extends BenchmarkBase {
  late ComponentCaste<double> caste1;
  late ComponentCaste<double> caste2;
  late ComponentCaste<double> caste3;
  late Query3<double, double, double> query;
  final int count;
  double _sum = 0;

  Query3Benchmark({this.count = 10000}) : super('Query3Iteration($count)');

  @override
  void run() {
    _sum = 0;
    query.forEach((e, c1, c2, c3) {
      _sum += c1 + c2 + c3;
    });
    // ignore: avoid_print
    if (_sum < 0) print(_sum); // Prevent optimization
  }

  @override
  void setup() {
    caste1 = ComponentCaste<double>(count);
    caste2 = ComponentCaste<double>(count);
    caste3 = ComponentCaste<double>(count);
    query = Query3<double, double, double>(caste1, caste2, caste3);
    for (int i = 0; i < count; i++) {
      caste1.add(i, i.toDouble());
      caste2.add(i, i.toDouble());
      caste3.add(i, i.toDouble());
    }
  }
}

void main() {
  Query1Benchmark().report();
  Query2Benchmark().report();
  Query3Benchmark().report();
}
