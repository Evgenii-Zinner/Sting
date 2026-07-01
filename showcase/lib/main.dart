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

import 'package:sting/engine/components/complex_ui.dart';
import 'package:sting/engine/components/ui_bounding_box.dart';
import 'package:sting/engine/systems/complex_ui_render_system.dart';
import 'package:sting/engine/systems/ui_system.dart';
import 'package:sting/engine/systems/sprite_render_system.dart';
import 'package:sting/engine/systems/animation_system.dart';
import 'package:sting/engine/components/tilemap.dart';
import 'package:sting/engine/systems/tilemap_render_system.dart';

import 'components/health.dart';
import 'components/damage.dart';
import 'components/exp_gem.dart';
import 'components/exp_magnet.dart';
import 'components/player_stats.dart';

import 'systems/gameplay_collision_system.dart';
import 'systems/player_stats_ui_system.dart';
import 'embedded_assets.dart';
import 'package:sting/engine/assets/asset_loader.dart';

class BulletHavenGame {
  final Scene scene;
  final Renderer renderer;
  final Image atlas;
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
  late final ComplexUIRenderSystem complexUIRenderSystem;
  late final UISystem mainUISystem;
  SpriteRenderSystem? spriteRenderSystem;
  late final AnimationSystem animationSystem;
  late final TilemapRenderSystem tilemapRenderSystem;

  int frameCount = 0;
  int playerEntityId = -1;
  int cameraEntityId = -1;

  // Track logic screen size for the player input center point
  double screenWidth = 0.0;
  double screenHeight = 0.0;

  BulletHavenGame(this.atlas)
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
    scene.registerCaste<ComplexUI>('ComplexUI', ComponentCaste<ComplexUI>(10));
    scene.registerCaste<UIBoundingBox>('UIBoundingBox', ComponentCaste<UIBoundingBox>(10));
    scene.registerCaste<Tilemap>('Tilemap', ComponentCaste<Tilemap>(1));

    // 2. Setup Global Game State Entity
    globalStateEntityId = scene.createEntity();
    gameStateSystem = GameStateSystem(scene.getCaste<GameState>('GameState'), globalStateEntityId);

    // Initial state is Menu, but for the showcase MVP we want it to run immediately
    gameStateSystem.changeState(GameState.statePlaying);

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

    scene.getCaste<ComplexUI>('ComplexUI').add(scoreId, ComplexUI(text: "Score: 0", x: 10, y: 10, width: 150, height: 20));
    scene.getCaste<ComplexUI>('ComplexUI').add(xpId, ComplexUI(text: "Lvl 1 | XP: 0 / 100", x: 10, y: 30, width: 200, height: 20));
    scene.getCaste<ComplexUI>('ComplexUI').add(healthId, ComplexUI(text: "HP: 100/100", x: 10, y: 50, width: 150, height: 20));

    scene.getCaste<UIBoundingBox>('UIBoundingBox').add(scoreId, UIBoundingBox.fromBounds(x: 10, y: 10, width: 150, height: 20));
    scene.getCaste<UIBoundingBox>('UIBoundingBox').add(xpId, UIBoundingBox.fromBounds(x: 10, y: 30, width: 200, height: 20));
    scene.getCaste<UIBoundingBox>('UIBoundingBox').add(healthId, UIBoundingBox.fromBounds(x: 10, y: 50, width: 150, height: 20));

    uiSystem = PlayerStatsUISystem(scene, scoreEntityId: scoreId, xpEntityId: xpId, healthEntityId: healthId);
    complexUIRenderSystem = ComplexUIRenderSystem(complexUICaste: scene.getCaste<ComplexUI>('ComplexUI'));
    mainUISystem = UISystem(scene.getCaste<UIBoundingBox>('UIBoundingBox'), inputSystem);

    // Initialize SpriteRenderSystem with a mock image for now.
    spriteRenderSystem = SpriteRenderSystem(
      atlas: atlas,
      positionCaste: scene.getCaste<Position>('Position'),
      spriteCaste: scene.getCaste<Sprite>('Sprite'),
      viewportCaste: scene.getCaste<Viewport>('Viewport'),
    );

    animationSystem = AnimationSystem(
      spriteCaste: scene.getCaste<Sprite>('Sprite'),
      spriteAnimationCaste: scene.getCaste<SpriteAnimation>('SpriteAnimation'),
    );

    tilemapRenderSystem = TilemapRenderSystem(
      atlas: atlas,
      positionCaste: scene.getCaste<Position>('Position'),
      tilemapCaste: scene.getCaste<Tilemap>('Tilemap'),
      viewportCaste: scene.getCaste<Viewport>('Viewport'),
    );

    // 4. Create entities
    cameraEntityId = scene.createEntity();
    scene.getCaste<Viewport>('Viewport').add(cameraEntityId, Viewport.create());

    spriteRenderSystem?.activeCameraEntity = cameraEntityId;
    tilemapRenderSystem.activeCameraEntity = cameraEntityId;

    final tilemapEntity = scene.createEntity();
    scene.getCaste<Position>('Position').add(tilemapEntity, Position.create(0.0, 0.0));
    final tilemap = Tilemap.create(100, 100, 32, 32);
    for (var col = 0; col < 100; col++) {
      for (var row = 0; row < 100; row++) {
        tilemap.setTile(col, row, 0);
      }
    }
    scene.getCaste<Tilemap>('Tilemap').add(tilemapEntity, tilemap);

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
      while (time.consumeFixedStep()) {
        if (gameStateSystem.shouldUpdateLogic()) {
          final dt = time.fixedDeltaTime;

          animationSystem.update(dt);
          mainUISystem.update();
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
      }

      dispatcher.scheduleFrame();
    };

    dispatcher.onDrawFrame = () {
      renderer.renderFrame(
        onRender: (canvas, size) {
          tilemapRenderSystem.render(canvas);
          spriteRenderSystem?.render(canvas);
          complexUIRenderSystem.render(canvas);
        },
      );
    };

    // Kick off
    dispatcher.scheduleFrame();
  }

  void startGame() {
    gameStateSystem.changeState(GameState.statePlaying);
  }
}

void main() async {
  final atlas = await AssetLoader.loadEmbeddedImage(EmbeddedAssets.assets['tilemap.png']!);
  BulletHavenGame(atlas);
}
