import 'package:sting/engine/ecs/entity_manager.dart';
import 'package:sting/engine/ecs/component_storage.dart';

class EntityManagerBenchmark {
  static double measureSpawning(int count) {
    // Warmup
    for (int i = 0; i < 5; i++) {
      var s = EntityManager();
      for (int j = 0; j < count; j++) {
        s.createEntity();
      }
    }

    final stopwatch = Stopwatch()..start();
    var swarm = EntityManager();
    for (int i = 0; i < count; i++) {
      swarm.createEntity();
    }
    stopwatch.stop();
    return stopwatch.elapsedMicroseconds.toDouble();
  }

  static double measureComponentAddition(int count) {
    // Warmup
    for (int i = 0; i < 5; i++) {
      final s = EntityManager();
      final tempCaste = ComponentStorage<double>(count);
      for (int j = 0; j < count; j++) {
        s.createEntity();
        tempCaste.add(j, j.toDouble());
      }
    }

    var swarm = EntityManager();
    final caste = ComponentStorage<double>(count);
    for (int i = 0; i < count; i++) {
      swarm.createEntity();
    }

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < count; i++) {
      caste.add(i, i.toDouble());
    }
    stopwatch.stop();
    return stopwatch.elapsedMicroseconds.toDouble();
  }

  static double measureComponentRemoval(int count) {
    // Warmup
    for (int i = 0; i < 5; i++) {
      final s = EntityManager();
      final tempCaste = ComponentStorage<double>(count);
      for (int j = 0; j < count; j++) {
        s.createEntity();
        tempCaste.add(j, j.toDouble());
      }
      for (int j = 0; j < count; j++) {
        tempCaste.remove(j);
      }
    }

    var swarm = EntityManager();
    final caste = ComponentStorage<double>(count);
    for (int i = 0; i < count; i++) {
      swarm.createEntity();
      caste.add(i, i.toDouble());
    }

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < count; i++) {
      caste.remove(i);
    }
    stopwatch.stop();
    return stopwatch.elapsedMicroseconds.toDouble();
  }
}

void main() {
  final count = 10000;
  // ignore: avoid_print
  print('SwarmSpawning($count): ${EntityManagerBenchmark.measureSpawning(count)} us.');
  // ignore: avoid_print
  print('ComponentAddition($count): ${EntityManagerBenchmark.measureComponentAddition(count)} us.');
  // ignore: avoid_print
  print('ComponentRemoval($count): ${EntityManagerBenchmark.measureComponentRemoval(count)} us.');
}
