import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/ecs/component_caste.dart';

// Create a dummy component and system that fits the engine
class DummyComponent {
  double value;
  DummyComponent(this.value);
}

class DummySystem {
  final Query1<DummyComponent> query;
  DummySystem(this.query);

  void update(double dt) {
    query.forEach((entity, comp) {
      comp.value += dt;
    });
  }
}

class SystemDispatchBenchmark extends BenchmarkBase {
  late List<DummySystem> systems;
  final int count;

  SystemDispatchBenchmark({this.count = 100}) : super('SystemDispatch($count)');

  @override
  void run() {
    for (int i = 0; i < count; i++) {
      systems[i].update(0.016);
    }
  }

  @override
  void setup() {
    final scene = Scene();
    final caste = ComponentCaste<DummyComponent>(10);
    scene.registerCaste('dummy', caste);
    final query = Query1<DummyComponent>(caste);

    systems = List.generate(count, (_) => DummySystem(query));
  }
}

void main() {
  SystemDispatchBenchmark().report();
}
