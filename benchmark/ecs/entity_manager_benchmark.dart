import 'package:sting/engine/ecs/entity_manager.dart';
import 'package:sting/engine/ecs/component_storage.dart';

void main() {
  final stopwatch = Stopwatch();
  final count = 10000;

  // EntityManager Spawning
  stopwatch.start();
  var swarm = EntityManager();
  for (int i = 0; i < count; i++) {
    swarm.createEntity();
  }
  stopwatch.stop();
  // ignore: avoid_print
  print('SwarmSpawning($count): ${stopwatch.elapsedMicroseconds} us.');
  stopwatch.reset();

  // Component Addition
  swarm = EntityManager();
  final caste = ComponentStorage<double>(count);
  for (int i = 0; i < count; i++) {
    swarm.createEntity();
  }

  stopwatch.start();
  for (int i = 0; i < count; i++) {
    caste.add(i, i.toDouble());
  }
  stopwatch.stop();
  // ignore: avoid_print
  print('ComponentAddition($count): ${stopwatch.elapsedMicroseconds} us.');
  stopwatch.reset();

  // Component Removal
  stopwatch.start();
  for (int i = 0; i < count; i++) {
    caste.remove(i);
  }
  stopwatch.stop();
  // ignore: avoid_print
  print('ComponentRemoval($count): ${stopwatch.elapsedMicroseconds} us.');
}
