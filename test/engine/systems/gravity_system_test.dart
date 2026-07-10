import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/mass.dart';
import 'package:sting/engine/components/game_state.dart';
import 'package:sting/engine/systems/game_state_system.dart';
import 'package:sting/engine/systems/gravity_system.dart';

void main() {
  group('GravitySystem', () {
    late Scene scene;
    late GameStateSystem gameStateSystem;
    late GravitySystem gravitySystem;
    late ComponentCaste<Position> posCaste;
    late ComponentCaste<Velocity> velCaste;
    late ComponentCaste<Mass> massCaste;
    late ComponentCaste<GameState> stateCaste;

    setUp(() {
      scene = Scene();
      posCaste = ComponentCaste<Position>(100);
      velCaste = ComponentCaste<Velocity>(100);
      massCaste = ComponentCaste<Mass>(100);
      stateCaste = ComponentCaste<GameState>(10);

      scene.registerCaste<Position>('Position', posCaste);
      scene.registerCaste<Velocity>('Velocity', velCaste);
      scene.registerCaste<Mass>('Mass', massCaste);
      scene.registerCaste<GameState>('GameState', stateCaste);

      gameStateSystem = GameStateSystem(stateCaste, 0);
      gameStateSystem.changeState(GameState.statePlaying);

      gravitySystem = GravitySystem(gameStateSystem, g: 10.0);
    });

    test('updates velocities based on gravity', () {
      // Entity 1: Heavy mass at origin
      posCaste.add(1, Position.create(0.0, 0.0));
      velCaste.add(1, Velocity.create(0.0, 0.0));
      massCaste.add(1, Mass.create(1000.0));

      // Entity 2: Light mass to the right
      posCaste.add(2, Position.create(10.0, 0.0));
      velCaste.add(2, Velocity.create(0.0, 0.0));
      massCaste.add(2, Mass.create(1.0));

      gravitySystem.update(scene, 1.0); // 1 second dt

      final vel1 = velCaste.get(1)!;
      final vel2 = velCaste.get(2)!;

      // Entity 1 should be pulled right slightly
      expect(vel1.dx, greaterThan(0.0));
      expect(vel1.dy, closeTo(0.0, 0.001));

      // Entity 2 should be pulled left significantly
      expect(vel2.dx, lessThan(0.0));
      expect(vel2.dy, closeTo(0.0, 0.001));

      // Since a = GM/d^2:
      // Entity 2 acceleration = (10.0 * 1000.0) / 100.0 = 100.0
      // So dx should be around -100.0 (ignoring softening and approx)
      expect(vel2.dx, closeTo(-100.0, 1.0));
    });

    test('does not update when game is paused', () {
      gameStateSystem.changeState(GameState.statePaused);

      posCaste.add(1, Position.create(0.0, 0.0));
      velCaste.add(1, Velocity.create(0.0, 0.0));
      massCaste.add(1, Mass.create(1000.0));

      posCaste.add(2, Position.create(10.0, 0.0));
      velCaste.add(2, Velocity.create(0.0, 0.0));
      massCaste.add(2, Mass.create(1.0));

      gravitySystem.update(scene, 1.0);

      final vel2 = velCaste.get(2)!;
      expect(vel2.dx, 0.0);
    });

    test('handles entities missing components', () {
      // Missing Mass
      posCaste.add(1, Position.create(0.0, 0.0));
      velCaste.add(1, Velocity.create(0.0, 0.0));

      // Missing Velocity
      posCaste.add(2, Position.create(10.0, 0.0));
      massCaste.add(2, Mass.create(1000.0));

      // Missing Position
      velCaste.add(3, Velocity.create(0.0, 0.0));
      massCaste.add(3, Mass.create(1.0));

      // Should not throw
      gravitySystem.update(scene, 1.0);
    });
    test(
        'respects custom softening parameter to cap gravitational force at close distance',
        () {
      final customGravitySystem =
          GravitySystem(gameStateSystem, g: 10.0, softening: 5.0);

      // Entity 1: Heavy mass at origin
      posCaste.add(1, Position.create(0.0, 0.0));
      velCaste.add(1, Velocity.create(0.0, 0.0));
      massCaste.add(1, Mass.create(1000.0));

      // Entity 2: Light mass extremely close (dist = 1.0)
      posCaste.add(2, Position.create(1.0, 0.0));
      velCaste.add(2, Velocity.create(0.0, 0.0));
      massCaste.add(2, Mass.create(1.0));

      customGravitySystem.update(scene, 1.0);

      final vel2 = velCaste.get(2)!;

      expect(vel2.dx, closeTo(-75.44, 0.1));
    });
  });
}
