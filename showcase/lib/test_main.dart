import 'dart:convert';
import 'dart:ui';
import 'dart:js_interop';

import 'package:sting/engine/assets/asset_loader.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/components/complex_ui.dart';

import 'embedded_assets.dart';
import 'main.dart';
import 'components/enemy_ai.dart';
import 'prefabs/enemy_prefab.dart';
import 'components/exp_gem.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'components/player_stats.dart';

@JS('getGameState')
external set _getGameState(JSFunction func);

void registerTestHooks(BulletHavenGame engine) {
  _getGameState = () {
    final positionCaste = engine.scene.getCaste<Position>('Position');
    final playerPos = positionCaste.get(engine.playerEntityId);

    final playerStatsCaste = engine.scene.getCaste<PlayerStats>('PlayerStats');
    final playerStats = playerStatsCaste.get(engine.playerEntityId);

    final enemyAiCaste = engine.scene.getCaste<EnemyAI>('EnemyAI');
    final enemyPositions = <Map<String, double>>[];

    for (int i = 0; i < enemyAiCaste.length; i++) {
      final entityId = enemyAiCaste.elementAt(i);
      final pos = positionCaste.get(entityId);
      if (pos != null) {
        enemyPositions.add({'x': pos.x, 'y': pos.y});
      }
    }

    final expGemCaste = engine.scene.getCaste<ExpGem>('ExpGem');
    final gemPositions = <Map<String, double>>[];
    for (int i = 0; i < expGemCaste.length; i++) {
      final entityId = expGemCaste.elementAt(i);
      final pos = positionCaste.get(entityId);
      if (pos != null) {
        gemPositions.add({'x': pos.x, 'y': pos.y});
      }
    }

    return jsonEncode({
      'player': {'x': playerPos?.x ?? 0.0, 'y': playerPos?.y ?? 0.0},
      'enemies': enemyPositions,
      'gems': gemPositions,
      'score': playerStats?.score ?? 0,
    }).toJS;
  }.toJS;
}

void main() async {
  final atlas = await AssetLoader.loadEmbeddedImage(EmbeddedAssets.assets['tilemap.png']!);
  final game = BulletHavenGame(atlas);

  registerTestHooks(game);

  // Manually place enemies deterministically
  spawnEnemy(game.scene, 100.0, 100.0, game.playerEntityId);
  spawnEnemy(game.scene, -100.0, 100.0, game.playerEntityId);
  spawnEnemy(game.scene, 100.0, -100.0, game.playerEntityId);

  // Manually place gems deterministically
  void spawnTestGem(double x, double y, int value) {
    final gemEntity = game.scene.createEntity();
    if (gemEntity != -1) {
      game.scene.getCaste<Position>('Position').add(gemEntity, Position.create(x, y));
      game.scene.getCaste<Velocity>('Velocity').add(gemEntity, Velocity.create(0.0, 0.0));
      game.scene.getCaste<BoundingBox>('BoundingBox').add(gemEntity, BoundingBox.create(8.0, 8.0));
      game.scene.getCaste<ExpGem>('ExpGem').add(gemEntity, ExpGem.create(value));
    }
  }

  spawnTestGem(50.0, 50.0, 10);
  spawnTestGem(-50.0, 50.0, 10);
  spawnTestGem(50.0, -50.0, 10);

  // Override the game loop to be deterministic for Playwright tests
  final dispatcher = PlatformDispatcher.instance;

  // Stop real-time scheduling
  dispatcher.onBeginFrame = (Duration timeStamp) {
    // No-op for real time ticks
  };

  // Manually tick the engine 10 times at 60 FPS (16666 microseconds per frame)
  for (int i = 1; i <= 10; i++) {
    game.frameCount++;
    game.time.update(i * 16666);

    while (game.time.consumeFixedStep()) {
      if (game.gameStateSystem.shouldUpdateLogic()) {
        final dt = game.time.fixedDeltaTime;
        game.animationSystem.update(dt);
        game.mainUISystem.update();
        game.playerInputSystem.update();
        // Disable random spawner for deterministic tests
        // game.enemySpawnerSystem.update(dt);
        game.chaseSystem.update();
        game.movementSystem.update(dt);
        game.spatialHashSystem.update(Query1<Position>(game.scene.getCaste<Position>('Position')));
        game.weaponSystem.update(dt);
        game.collisionSystem.update(game.playerEntityId);
        game.uiSystem.update(game.playerEntityId);
        game.cameraSystem.update(game.cameraEntityId, game.playerEntityId);
      }
    }
  }

  // Draw exactly one frame after the state is settled
  dispatcher.onDrawFrame = () {
    game.renderer.renderFrame(
      onRender: (canvas, size) {
        game.tilemapRenderSystem.render(canvas);
        game.spriteRenderSystem?.render(canvas);
        game.complexUIRenderSystem.render(canvas);
      },
    );
  };

  // Trigger the one deterministic draw
  dispatcher.scheduleFrame();
}
