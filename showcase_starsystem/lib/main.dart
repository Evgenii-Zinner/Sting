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
import 'package:sting/engine/components/complex_ui.dart';
import 'package:sting/engine/components/ui_bounding_box.dart';
import 'package:sting/engine/systems/complex_ui_render_system.dart';
import 'package:sting/engine/systems/input_system.dart';
import 'package:sting/engine/systems/input_mapping_system.dart';
import 'package:sting/engine/systems/ui_system.dart';
import 'package:sting/engine/components/parallax.dart';
import 'package:sting/engine/systems/parallax_system.dart';
import 'package:sting/engine/components/virtual_joypad.dart';
import 'package:sting/engine/systems/virtual_joypad_system.dart';
import 'package:flutter/services.dart';

import 'embedded_assets.dart';
import 'package:sting/engine/assets/asset_loader.dart';
import 'dart:math' as math;

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
  late final InputSystem inputSystem;
  late final InputMappingSystem inputMappingSystem;
  late final UISystem uiSystem;
  late final ComplexUIRenderSystem complexUIRenderSystem;
  late final ParallaxSystem parallaxSystem;
  late final VirtualJoypadSystem virtualJoypadSystem;

  int frameCount = 0;
  int cameraEntityId = -1;
  int joypadEntityId = -1;

  double screenWidth = 0.0;
  double screenHeight = 0.0;

  int spawnPlanetBtnId = -1;
  int spawnAsteroidBtnId = -1;
  int spawnCometBtnId = -1;

  bool _wasPlanetBtnPressed = false;
  bool _wasAsteroidBtnPressed = false;
  bool _wasCometBtnPressed = false;

  final math.Random _random = math.Random();

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
    scene.registerCaste<ComplexUI>('ComplexUI', ComponentCaste<ComplexUI>(Swarm.maxEntities));
    scene.registerCaste<UIBoundingBox>('UIBoundingBox', ComponentCaste<UIBoundingBox>(Swarm.maxEntities));
    scene.registerCaste<Parallax>('Parallax', ComponentCaste<Parallax>(Swarm.maxEntities));
    scene.registerCaste<VirtualJoypad>('VirtualJoypad', ComponentCaste<VirtualJoypad>(10));

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

    inputSystem = InputSystem();
    inputMappingSystem = InputMappingSystem(inputSystem);
    inputMappingSystem.bindKey(LogicalKeyboardKey.arrowUp.keyId, GameAction.moveUp);
    inputMappingSystem.bindKey(LogicalKeyboardKey.arrowDown.keyId, GameAction.moveDown);
    inputMappingSystem.bindKey(LogicalKeyboardKey.arrowLeft.keyId, GameAction.moveLeft);
    inputMappingSystem.bindKey(LogicalKeyboardKey.arrowRight.keyId, GameAction.moveRight);

    parallaxSystem = ParallaxSystem(
      positionCaste: scene.getCaste<Position>('Position'),
      parallaxCaste: scene.getCaste<Parallax>('Parallax'),
      viewportCaste: scene.getCaste<Viewport>('Viewport'),
    );

    virtualJoypadSystem = VirtualJoypadSystem(
      scene.getCaste<VirtualJoypad>('VirtualJoypad'),
      scene.getCaste<UIBoundingBox>('UIBoundingBox'),
      scene.getCaste<ComplexUI>('ComplexUI'),
      inputSystem,
    );

    uiSystem = UISystem(
      scene.getCaste<UIBoundingBox>('UIBoundingBox'),
      inputSystem,
    );
    complexUIRenderSystem = ComplexUIRenderSystem(
      complexUICaste: scene.getCaste<ComplexUI>('ComplexUI'),
    );

    // 4. Create Camera
    cameraEntityId = scene.createEntity();
    final viewport = Viewport.create();
    // Center camera slightly if we want, or rely on objects
    viewport.x = -400; // Assuming objects around 0,0, this centers 0,0 on an 800x600 screen
    viewport.y = -300;
    scene.getCaste<Viewport>('Viewport').add(cameraEntityId, viewport);

    spriteRenderSystem?.activeCameraEntity = cameraEntityId;
    parallaxSystem.activeCameraEntity = cameraEntityId;

    // Spawn a parallax starfield background
    final bgEntityId = scene.createEntity();
    scene.getCaste<Position>('Position').add(bgEntityId, Position.create(0.0, 0.0));
    final bgSprite = Sprite.create();
    bgSprite.rectLeft = 0; bgSprite.rectTop = 0; bgSprite.rectRight = 64; bgSprite.rectBottom = 64;
    scene.getCaste<Sprite>('Sprite').add(bgEntityId, bgSprite);
    scene.getCaste<Parallax>('Parallax').add(bgEntityId, Parallax.create(0.2, 0.2, 0.0, 0.0)); // moves slowly

    _spawnStarSystem();
    _createUI();

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

      // Ensure UI buttons have correct physical bounds before checking interaction
      _updateUIBounds();

      // UI Interaction
      uiSystem.update();
      virtualJoypadSystem.update();
      _handleUIInteractions();

      _updateCamera(time.fixedDeltaTime);

      while (time.consumeFixedStep()) {
        if (gameStateSystem.shouldUpdateLogic()) {
          final dt = time.fixedDeltaTime;
          gravitySystem.update(scene, dt);
          movementSystem.update(dt);
          parallaxSystem.update();
        }
      }

      dispatcher.scheduleFrame();
    };

    dispatcher.onDrawFrame = () {
      renderer.renderFrame(
        onRender: (canvas, size) {
          spriteRenderSystem?.render(canvas);
          complexUIRenderSystem.render(canvas);
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

  void _createUI() {
    // Planet Button
    spawnPlanetBtnId = scene.createEntity();
    scene.getCaste<ComplexUI>('ComplexUI').add(spawnPlanetBtnId, ComplexUI(
      text: 'Spawn Planet', x: 10, y: 10, width: 200, height: 40,
      backgroundColor: 0xFF444444, textColor: 0xFFFFFFFF, borderRadius: 4.0, fontSize: 16.0,
    ));
    scene.getCaste<UIBoundingBox>('UIBoundingBox').add(spawnPlanetBtnId, UIBoundingBox.fromBounds(x: 10, y: 10, width: 200, height: 40));

    // Asteroid Button
    spawnAsteroidBtnId = scene.createEntity();
    scene.getCaste<ComplexUI>('ComplexUI').add(spawnAsteroidBtnId, ComplexUI(
      text: 'Spawn Heavy Asteroid', x: 10, y: 60, width: 200, height: 40,
      backgroundColor: 0xFF444444, textColor: 0xFFFFFFFF, borderRadius: 4.0, fontSize: 16.0,
    ));
    scene.getCaste<UIBoundingBox>('UIBoundingBox').add(spawnAsteroidBtnId, UIBoundingBox.fromBounds(x: 10, y: 60, width: 200, height: 40));

    // Comet Button
    spawnCometBtnId = scene.createEntity();
    scene.getCaste<ComplexUI>('ComplexUI').add(spawnCometBtnId, ComplexUI(
      text: 'Spawn Fast Comet', x: 10, y: 110, width: 200, height: 40,
      backgroundColor: 0xFF444444, textColor: 0xFFFFFFFF, borderRadius: 4.0, fontSize: 16.0,
    ));
    scene.getCaste<UIBoundingBox>('UIBoundingBox').add(spawnCometBtnId, UIBoundingBox.fromBounds(x: 10, y: 110, width: 200, height: 40));

    // Virtual Joypad for camera control
    joypadEntityId = scene.createEntity();
    final knobEntityId = scene.createEntity();

    scene.getCaste<ComplexUI>('ComplexUI').add(joypadEntityId, ComplexUI(
      x: 20, y: 400, width: 120, height: 120,
      backgroundColor: 0x44FFFFFF, borderRadius: 60.0,
    ));
    scene.getCaste<UIBoundingBox>('UIBoundingBox').add(joypadEntityId, UIBoundingBox.fromBounds(x: 20, y: 400, width: 120, height: 120));
    scene.getCaste<VirtualJoypad>('VirtualJoypad').add(joypadEntityId, VirtualJoypad.create(
      maxRadius: 60.0, centerX: 80.0, centerY: 460.0, knobEntityId: knobEntityId.toDouble()
    ));

    scene.getCaste<ComplexUI>('ComplexUI').add(knobEntityId, ComplexUI(
      x: 60, y: 440, width: 40, height: 40,
      backgroundColor: 0x88FFFFFF, borderRadius: 20.0,
    ));
  }

  void _updateUIBounds() {
    final dispatcher = PlatformDispatcher.instance;
    if (dispatcher.views.isEmpty) return;

    final view = dispatcher.views.first;
    final physicalSize = view.physicalSize;
    if (physicalSize.isEmpty) return;

    final rect = renderer.calculateVirtualRect(physicalSize);
    double scale = rect.width / (renderer.virtualWidth ?? 800);

    void updateBox(int entityId, double vx, double vy, double vw, double vh) {
      if (entityId == -1) return;
      final box = scene.getCaste<UIBoundingBox>('UIBoundingBox').get(entityId);
      if (box != null) {
        box.x = rect.left + vx * scale;
        box.y = rect.top + vy * scale;
        box.width = vw * scale;
        box.height = vh * scale;
      }
    }

    updateBox(spawnPlanetBtnId, 10, 10, 200, 40);
    updateBox(spawnAsteroidBtnId, 10, 60, 200, 40);
    updateBox(spawnCometBtnId, 10, 110, 200, 40);

    double jX = 20.0;
    double jY = (renderer.virtualHeight ?? 600) - 140.0;
    double jSize = 120.0;

    updateBox(joypadEntityId, jX, jY, jSize, jSize);

    final joypadComp = scene.getCaste<VirtualJoypad>('VirtualJoypad').get(joypadEntityId);
    if (joypadComp != null) {
       joypadComp.centerX = rect.left + (jX + jSize/2) * scale;
       joypadComp.centerY = rect.top + (jY + jSize/2) * scale;
       joypadComp.maxRadius = (jSize/2) * scale;
    }

    final joypadUI = scene.getCaste<ComplexUI>('ComplexUI').get(joypadEntityId);
    if (joypadUI != null) {
       joypadUI.x = jX;
       joypadUI.y = jY;
       joypadUI.width = jSize;
       joypadUI.height = jSize;
    }
  }

  void _updateCamera(double dt) {
    if (cameraEntityId == -1) return;
    final viewport = scene.getCaste<Viewport>('Viewport').get(cameraEntityId);
    if (viewport == null) return;

    double moveX = 0.0;
    double moveY = 0.0;
    final speed = 300.0;

    // Keyboard
    if (inputMappingSystem.isActionActive(GameAction.moveRight)) moveX += 1.0;
    if (inputMappingSystem.isActionActive(GameAction.moveLeft)) moveX -= 1.0;
    if (inputMappingSystem.isActionActive(GameAction.moveDown)) moveY += 1.0;
    if (inputMappingSystem.isActionActive(GameAction.moveUp)) moveY -= 1.0;

    // Joypad
    final joypad = scene.getCaste<VirtualJoypad>('VirtualJoypad').get(joypadEntityId);
    if (joypad != null) {
      if (joypad.vectorX != 0.0 || joypad.vectorY != 0.0) {
         moveX = joypad.vectorX;
         moveY = joypad.vectorY;
      }
    }

    if (moveX != 0.0 || moveY != 0.0) {
      final length = math.sqrt(moveX * moveX + moveY * moveY);
      if (length > 1.0) {
         moveX /= length;
         moveY /= length;
      }
      viewport.x += moveX * speed * dt;
      viewport.y += moveY * speed * dt;
    }
  }

  void _handleUIInteractions() {
    void handleBtn(int entityId, bool wasPressed, void Function(bool) setPressed, void Function() onSpawn) {
      if (entityId == -1) return;
      final box = scene.getCaste<UIBoundingBox>('UIBoundingBox').get(entityId);
      if (box != null) {
        bool isPressed = box.pointerId != -1.0;
        if (isPressed && !wasPressed) {
          setPressed(true);
          onSpawn();
        } else if (!isPressed) {
          setPressed(false);
        }
      }
    }

    handleBtn(spawnPlanetBtnId, _wasPlanetBtnPressed, (v) => _wasPlanetBtnPressed = v, () => _spawnEntity(10.0, 1.0, 96, 0, 112, 16));
    handleBtn(spawnAsteroidBtnId, _wasAsteroidBtnPressed, (v) => _wasAsteroidBtnPressed = v, () => _spawnEntity(50.0, 0.8, 112, 0, 128, 16)); // Heavy, slower
    handleBtn(spawnCometBtnId, _wasCometBtnPressed, (v) => _wasCometBtnPressed = v, () => _spawnEntity(2.0, 1.5, 128, 0, 144, 16)); // Light, faster
  }

  void _spawnEntity(double mass, double velocityMultiplier, int srcL, int srcT, int srcR, int srcB) {
    int entityId = scene.createEntity();

    double r = 100.0 + _random.nextDouble() * 300.0;
    double angle = _random.nextDouble() * math.pi * 2;
    double x = r * math.cos(angle);
    double y = r * math.sin(angle);

    double v = math.sqrt(50.0 * 10000 / r) * velocityMultiplier;
    double dx = -y / r * v;
    double dy = x / r * v;

    scene.getCaste<Position>('Position').add(entityId, Position.create(x, y));
    scene.getCaste<Velocity>('Velocity').add(entityId, Velocity.create(dx, dy));
    scene.getCaste<Mass>('Mass').add(entityId, Mass.create(mass));

    final sprite = Sprite.create();
    sprite.rectLeft = srcL.toDouble();
    sprite.rectTop = srcT.toDouble();
    sprite.rectRight = srcR.toDouble();
    sprite.rectBottom = srcB.toDouble();
    sprite.transformTx = -(srcR - srcL) / 2.0;
    sprite.transformTy = -(srcB - srcT) / 2.0;
    scene.getCaste<Sprite>('Sprite').add(entityId, sprite);
  }

  void startGame() {
    gameStateSystem.changeState(GameState.statePlaying);
  }
}

void main() async {
  final atlas = await AssetLoader.loadEmbeddedImage(EmbeddedAssets.assets['atlas.png']!);
  StarSystemGame(atlas);
}
