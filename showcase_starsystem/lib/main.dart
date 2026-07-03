import 'dart:ui';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/time.dart';
import 'package:sting/engine/renderer.dart';

import 'package:sting/engine/components/game_state.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/mass.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/viewport.dart';

import 'package:sting/engine/systems/game_state_system.dart';
import 'package:sting/engine/systems/gravity_system.dart';
import 'package:sting/engine/systems/movement_system.dart';
import 'package:sting/engine/systems/sprite_render_system.dart';

import 'embedded_assets.dart';
import 'package:sting/engine/assets/asset_loader.dart';

class StarSystemGame {
  final Scene scene;
  final Renderer renderer;
  final Image atlas;
  final Time time;
  late final GameStateSystem gameStateSystem;
  late final int globalStateEntityId;

  // Subsystems
  late final MovementSystem movementSystem;
  late final GravitySystem gravitySystem;
  SpriteRenderSystem? spriteRenderSystem;

  int frameCount = 0;
  int cameraEntityId = -1;

  double screenWidth = 0.0;
  double screenHeight = 0.0;

  StarSystemGame(this.atlas)
      : scene = Scene(),
        renderer = Renderer(virtualWidth: 800, virtualHeight: 600),
        time = Time() {
    _initEngine();
  }

  void _initEngine() {
    // 1. Register Castes
    scene.registerCaste<GameState>('GameState', ComponentCaste<GameState>(1));
    scene.registerCaste<Position>('Position', ComponentCaste<Position>(Swarm.maxEntities));
    scene.registerCaste<Velocity>('Velocity', ComponentCaste<Velocity>(Swarm.maxEntities));
    scene.registerCaste<Mass>('Mass', ComponentCaste<Mass>(Swarm.maxEntities));
    scene.registerCaste<Sprite>('Sprite', ComponentCaste<Sprite>(Swarm.maxEntities));
    scene.registerCaste<Viewport>('Viewport', ComponentCaste<Viewport>(1));

    // 2. Setup Global Game State Entity
    globalStateEntityId = scene.createEntity();
    gameStateSystem = GameStateSystem(scene.getCaste<GameState>('GameState'), globalStateEntityId);
    gameStateSystem.changeState(GameState.statePlaying);

    // 3. Initialize Systems
    movementSystem = MovementSystem(
      positionCaste: scene.getCaste<Position>('Position'),
      velocityCaste: scene.getCaste<Velocity>('Velocity'),
    );

    gravitySystem = GravitySystem(
      gameStateSystem,
      theta: 0.5,
      g: 50.0,
      maxNodes: 1000,
    );

    spriteRenderSystem = SpriteRenderSystem(
      atlas: atlas,
      positionCaste: scene.getCaste<Position>('Position'),
      spriteCaste: scene.getCaste<Sprite>('Sprite'),
      viewportCaste: scene.getCaste<Viewport>('Viewport'),
    );

    // 4. Create Camera
    cameraEntityId = scene.createEntity();
    final viewport = Viewport.create();
    // Center camera slightly if we want, or rely on objects
    viewport.x = -400; // Assuming objects around 0,0, this centers 0,0 on an 800x600 screen
    viewport.y = -300;
    scene.getCaste<Viewport>('Viewport').add(cameraEntityId, viewport);

    spriteRenderSystem?.activeCameraEntity = cameraEntityId;

    _spawnStarSystem();

    // 5. Setup Platform Dispatcher
    final dispatcher = PlatformDispatcher.instance;

    dispatcher.onMetricsChanged = () {
      if (dispatcher.views.isNotEmpty) {
        final window = dispatcher.views.first;
        screenWidth = window.physicalSize.width / window.devicePixelRatio;
        screenHeight = window.physicalSize.height / window.devicePixelRatio;
      }
    };

    if (dispatcher.views.isNotEmpty) {
      final window = dispatcher.views.first;
      screenWidth = window.physicalSize.width / window.devicePixelRatio;
      screenHeight = window.physicalSize.height / window.devicePixelRatio;
    }

    dispatcher.onBeginFrame = (Duration timeStamp) {
      frameCount++;
      time.update(timeStamp.inMicroseconds);

      while (time.consumeFixedStep()) {
        if (gameStateSystem.shouldUpdateLogic()) {
          final dt = time.fixedDeltaTime;
          gravitySystem.update(scene, dt);
          movementSystem.update(dt);
        }
      }

      dispatcher.scheduleFrame();
    };

    dispatcher.onDrawFrame = () {
      renderer.renderFrame(
        onRender: (canvas, size) {
          spriteRenderSystem?.render(canvas);
        },
      );
    };

    // Kick off
    dispatcher.scheduleFrame();
  }

  void _spawnStarSystem() {
    // 1. Central Star (Massive, immobile initially, but let's see if we want it to move. Typically big mass)
    int starId = scene.createEntity();
    scene.getCaste<Position>('Position').add(starId, Position.create(0, 0));
    scene.getCaste<Velocity>('Velocity').add(starId, Velocity.create(0, 0));
    scene.getCaste<Mass>('Mass').add(starId, Mass.create(10000)); // Big mass

    final starSprite = Sprite.create();
    starSprite.rectLeft = 0;
    starSprite.rectTop = 0;
    starSprite.rectRight = 64;
    starSprite.rectBottom = 64;
    // Offset by -32 to center the 64x64 sprite on the position
    starSprite.transformTx = -32;
    starSprite.transformTy = -32;
    scene.getCaste<Sprite>('Sprite').add(starId, starSprite);

    // 2. Planet 1 (Inner orbit)
    // To achieve circular orbit: v = sqrt(G * M / r)
    // G = 50.0, M = 10000, r = 150
    // v = sqrt(50 * 10000 / 150) = sqrt(3333.3) ≈ 57.7
    int planet1Id = scene.createEntity();
    scene.getCaste<Position>('Position').add(planet1Id, Position.create(150, 0));
    scene.getCaste<Velocity>('Velocity').add(planet1Id, Velocity.create(0, 57.7)); // Orbiting velocity
    scene.getCaste<Mass>('Mass').add(planet1Id, Mass.create(10)); // Small mass

    final planet1Sprite = Sprite.create();
    planet1Sprite.rectLeft = 64;
    planet1Sprite.rectTop = 0;
    planet1Sprite.rectRight = 96;
    planet1Sprite.rectBottom = 32;
    planet1Sprite.transformTx = -16;
    planet1Sprite.transformTy = -16;
    scene.getCaste<Sprite>('Sprite').add(planet1Id, planet1Sprite);

    // 3. Planet 2 (Outer orbit)
    // r = 300, v = sqrt(50 * 10000 / 300) = sqrt(1666.6) ≈ 40.8
    int planet2Id = scene.createEntity();
    scene.getCaste<Position>('Position').add(planet2Id, Position.create(0, -300));
    scene.getCaste<Velocity>('Velocity').add(planet2Id, Velocity.create(40.8, 0));
    scene.getCaste<Mass>('Mass').add(planet2Id, Mass.create(5));

    final planet2Sprite = Sprite.create();
    planet2Sprite.rectLeft = 96;
    planet2Sprite.rectTop = 0;
    planet2Sprite.rectRight = 112;
    planet2Sprite.rectBottom = 16;
    planet2Sprite.transformTx = -8;
    planet2Sprite.transformTy = -8;
    scene.getCaste<Sprite>('Sprite').add(planet2Id, planet2Sprite);
  }

  void startGame() {
    gameStateSystem.changeState(GameState.statePlaying);
  }
}

void main() async {
  final atlas = await AssetLoader.loadEmbeddedImage(EmbeddedAssets.assets['atlas.png']!);
  StarSystemGame(atlas);
}
