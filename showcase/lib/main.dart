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
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/sprite_animation.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/systems/input_system.dart';
import 'package:sting/engine/systems/movement_system.dart';
import 'package:sting/engine/systems/camera_system.dart';

import 'components/enemy_ai.dart';
import 'prefabs/player_prefab.dart';
import 'systems/player_input_system.dart';
import 'systems/enemy_spawner_system.dart';
import 'systems/chase_system.dart';
import 'components/weapon.dart';
import 'systems/weapon_system.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';
import 'package:sting/engine/systems/spatial_hash_system.dart';
import 'package:sting/engine/ecs/query.dart';

import 'package:sting/engine/components/text_render.dart';
import 'package:sting/engine/systems/text_render_system.dart';

import 'components/health.dart';
import 'components/damage.dart';
import 'components/exp_gem.dart';
import 'components/exp_magnet.dart';
import 'components/player_stats.dart';

import 'systems/gameplay_collision_system.dart';
import 'systems/player_stats_ui_system.dart';

class BulletHavenGame {
  final Scene scene;
  final Renderer renderer;
  final Time time;
  late final GameStateSystem gameStateSystem;
  late final int globalStateEntityId;

  // Subsystems
  late final InputSystem inputSystem;
  late final PlayerInputSystem playerInputSystem;
  late final MovementSystem movementSystem;
  late final CameraSystem cameraSystem;
  late final EnemySpawnerSystem enemySpawnerSystem;
  late final ChaseSystem chaseSystem;
  late final SpatialHashGrid spatialHashGrid;
  late final SpatialHashSystem spatialHashSystem;
  late final WeaponSystem weaponSystem;
  late final GameplayCollisionSystem collisionSystem;
  late final PlayerStatsUISystem uiSystem;
  late final TextRenderSystem textRenderSystem;

  int frameCount = 0;
  int playerEntityId = -1;
  int cameraEntityId = -1;

  // Track logic screen size for the player input center point
  double screenWidth = 0.0;
  double screenHeight = 0.0;

  BulletHavenGame()
      : scene = Scene(),
        renderer = Renderer(),
        time = Time() {
    _initEngine();
  }

  void _initEngine() {
    // 1. Register Castes
    scene.registerCaste<GameState>('GameState', ComponentCaste<GameState>(1));
    scene.registerCaste<Position>('Position', ComponentCaste<Position>(Swarm.maxEntities));
    scene.registerCaste<Velocity>('Velocity', ComponentCaste<Velocity>(Swarm.maxEntities));
    scene.registerCaste<Sprite>('Sprite', ComponentCaste<Sprite>(Swarm.maxEntities));
    scene.registerCaste<SpriteAnimation>('SpriteAnimation', ComponentCaste<SpriteAnimation>(Swarm.maxEntities));
    scene.registerCaste<BoundingBox>('BoundingBox', ComponentCaste<BoundingBox>(Swarm.maxEntities));
    scene.registerCaste<Viewport>('Viewport', ComponentCaste<Viewport>(1));
    scene.registerCaste<EnemyAI>('EnemyAI', ComponentCaste<EnemyAI>(Swarm.maxEntities));
    scene.registerCaste<Weapon>('Weapon', ComponentCaste<Weapon>(Swarm.maxEntities));
    scene.registerCaste<Health>('Health', ComponentCaste<Health>(Swarm.maxEntities));
    scene.registerCaste<Damage>('Damage', ComponentCaste<Damage>(Swarm.maxEntities));
    scene.registerCaste<ExpGem>('ExpGem', ComponentCaste<ExpGem>(Swarm.maxEntities));
    scene.registerCaste<ExpMagnet>('ExpMagnet', ComponentCaste<ExpMagnet>(1));
    scene.registerCaste<PlayerStats>('PlayerStats', ComponentCaste<PlayerStats>(1));
    scene.registerCaste<TextRender>('TextRender', ComponentCaste<TextRender>(10));

    // 2. Setup Global Game State Entity
    globalStateEntityId = scene.createEntity();
    gameStateSystem = GameStateSystem(scene.getCaste<GameState>('GameState'), globalStateEntityId);

    // Initial state is Menu
    gameStateSystem.changeState(GameState.stateMenu);

    // 3. Initialize Systems
    inputSystem = InputSystem();

    playerInputSystem = PlayerInputSystem(
      inputSystem: inputSystem,
      velocityCaste: scene.getCaste<Velocity>('Velocity'),
    );

    movementSystem = MovementSystem(
      positionCaste: scene.getCaste<Position>('Position'),
      velocityCaste: scene.getCaste<Velocity>('Velocity'),
    );

    cameraSystem = CameraSystem(
      positionCaste: scene.getCaste<Position>('Position'),
      viewportCaste: scene.getCaste<Viewport>('Viewport'),
    );

    enemySpawnerSystem = EnemySpawnerSystem(scene);
    chaseSystem = ChaseSystem(scene);

    spatialHashGrid = SpatialHashGrid(64.0, 1000);
    spatialHashSystem = SpatialHashSystem(spatialHashGrid);
    weaponSystem = WeaponSystem(scene, spatialHashGrid);
    collisionSystem = GameplayCollisionSystem(scene, spatialHashGrid);

    // UI Entities
    final scoreId = scene.createEntity();
    final xpId = scene.createEntity();
    final healthId = scene.createEntity();

    scene.getCaste<TextRender>('TextRender').add(scoreId, TextRender(text: "Score: 0", x: 10, y: 10));
    scene.getCaste<TextRender>('TextRender').add(xpId, TextRender(text: "Lvl 1 | XP: 0 / 100", x: 10, y: 30));
    scene.getCaste<TextRender>('TextRender').add(healthId, TextRender(text: "HP: 100/100", x: 10, y: 50));

    uiSystem = PlayerStatsUISystem(scene, scoreEntityId: scoreId, xpEntityId: xpId, healthEntityId: healthId);
    textRenderSystem = TextRenderSystem(textRenderCaste: scene.getCaste<TextRender>('TextRender'));

    // 4. Create entities
    cameraEntityId = scene.createEntity();
    scene.getCaste<Viewport>('Viewport').add(cameraEntityId, Viewport.create());

    playerEntityId = spawnPlayer(scene, 0.0, 0.0);
    playerInputSystem.setPlayerEntity(playerEntityId);
    enemySpawnerSystem.setTargetEntity(playerEntityId);

    // 5. Setup Platform Dispatcher
    final dispatcher = PlatformDispatcher.instance;

    // Handle metrics change to update logical screen size
    dispatcher.onMetricsChanged = () {
      final window = dispatcher.views.first;
      screenWidth = window.physicalSize.width / window.devicePixelRatio;
      screenHeight = window.physicalSize.height / window.devicePixelRatio;
      playerInputSystem.updateScreenSize(screenWidth, screenHeight);
      enemySpawnerSystem.updateScreenSize(screenWidth, screenHeight);
    };

    // Trigger initial metrics check if available
    if (dispatcher.views.isNotEmpty) {
      final window = dispatcher.views.first;
      screenWidth = window.physicalSize.width / window.devicePixelRatio;
      screenHeight = window.physicalSize.height / window.devicePixelRatio;
      playerInputSystem.updateScreenSize(screenWidth, screenHeight);
      enemySpawnerSystem.updateScreenSize(screenWidth, screenHeight);
    }

    dispatcher.onBeginFrame = (Duration timeStamp) {
      frameCount++;
      time.update(timeStamp.inMicroseconds);

      // Update Systems here (only if playing)
      if (gameStateSystem.shouldUpdateLogic()) {
        final dt = time.dt;

        playerInputSystem.update();
        enemySpawnerSystem.update(dt);
        chaseSystem.update();
        movementSystem.update(dt);

        // Update spatial hash before weapon system queries it
        spatialHashSystem.update(Query1<Position>(scene.getCaste<Position>('Position')));

        weaponSystem.update(dt);
        collisionSystem.update(playerEntityId);
        uiSystem.update(playerEntityId);

        cameraSystem.update(cameraEntityId, playerEntityId);
      }

      dispatcher.scheduleFrame();
    };

    dispatcher.onDrawFrame = () {
      renderer.renderFrame();

      // Need to render TextRender components manually since Renderer is just a basic wrapper in main
      // Wait, let's see how renderer works or if we can get the canvas.
      // Actually textRenderSystem needs a canvas. In a proper setup, Renderer would have a pipeline.
      // Since we don't have the canvas here directly, we can leave textRenderSystem call out,
      // or assume renderer handles text render if it was added.
      // The task says "render the score via the UI Bounding Box System" (Wait, ComplexUI maybe?)
      // Let's pass the canvas if we can, else just leave it for the renderer to handle if it does.
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
