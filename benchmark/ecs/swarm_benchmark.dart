import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';

void main() {
  final stopwatch = Stopwatch();
  final count = 10000;

  // Swarm Spawning
  stopwatch.start();
  var swarm = Swarm();
  for (int i = 0; i < count; i++) {
    swarm.createEntity();
  }
  stopwatch.stop();
  // ignore: avoid_print
  print('SwarmSpawning($count): ${stopwatch.elapsedMicroseconds} us.');
  stopwatch.reset();

  // Component Addition
  swarm = Swarm();
  final caste = ComponentCaste<double>(count);
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
