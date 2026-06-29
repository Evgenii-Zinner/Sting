import 'dart:ui';
import 'package:sting/engine/renderer.dart';
import 'package:sting/engine/time.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/game_state.dart';
import 'package:sting/engine/systems/game_state_system.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';

class BulletHavenGame {
  final Scene scene;
  final Renderer renderer;
  final Time time;
  late final GameStateSystem gameStateSystem;
  late final int globalStateEntityId;
  int frameCount = 0;

  BulletHavenGame()
      : scene = Scene(),
        renderer = Renderer(),
        time = Time() {
    _initEngine();
  }

  void _initEngine() {
    // 1. Register Castes
    // Use Swarm.maxEntities for castes that might be common (like Position)
    // Or smaller capacity depending on usage. For now, maxEntities for everything common.
    scene.registerCaste<GameState>('GameState', ComponentCaste<GameState>(1));
    scene.registerCaste<Position>('Position', ComponentCaste<Position>(Swarm.maxEntities));
    scene.registerCaste<Velocity>('Velocity', ComponentCaste<Velocity>(Swarm.maxEntities));

    // 2. Setup Global Game State Entity
    globalStateEntityId = scene.createEntity();
    gameStateSystem = GameStateSystem(scene.getCaste<GameState>('GameState'), globalStateEntityId);

    // Initial state is Menu
    gameStateSystem.changeState(GameState.stateMenu);

    // 3. Setup Platform Dispatcher
    final dispatcher = PlatformDispatcher.instance;

    dispatcher.onBeginFrame = (Duration timeStamp) {
      frameCount++;
      time.update(timeStamp.inMicroseconds);

      // Update Systems here (only if playing)
      if (gameStateSystem.shouldUpdateLogic()) {
        // Run update logic
      }

      dispatcher.scheduleFrame();
    };

    dispatcher.onDrawFrame = () {
      renderer.renderFrame();
      // Additional rendering logic
    };

    // Kick off
    dispatcher.scheduleFrame();
  }

  void startGame() {
    gameStateSystem.changeState(GameState.statePlaying);
  }
}

void main() {
  BulletHavenGame();
}
