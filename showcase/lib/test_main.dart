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

@JS('getGameState')
external set _getGameState(JSFunction func);

void registerTestHooks(BulletHavenGame engine) {
  _getGameState = () {
    final positionCaste = engine.scene.getCaste<Position>('Position');
    final playerPos = positionCaste.get(engine.playerEntityId);

    final enemyAiCaste = engine.scene.getCaste<EnemyAI>('EnemyAI');
    final enemyPositions = <Map<String, double>>[];

    for (int i = 0; i < enemyAiCaste.length; i++) {
      final entityId = enemyAiCaste.elementAt(i);
      final pos = positionCaste.get(entityId);
      if (pos != null) {
        enemyPositions.add({'x': pos.x, 'y': pos.y});
      }
    }

    return jsonEncode({
      'player': {'x': playerPos?.x ?? 0.0, 'y': playerPos?.y ?? 0.0},
      'enemies': enemyPositions,
      'score': 0, // Placeholder
    }).toJS;
  }.toJS;
}

void main() async {
  final atlas = await AssetLoader.loadEmbeddedImage(EmbeddedAssets.assets['tilemap.png']!);
  final game = BulletHavenGame(atlas);

  registerTestHooks(game);

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
        game.mainUISystem.update();
        game.playerInputSystem.update();
        game.enemySpawnerSystem.update(dt);
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
        game.spriteRenderSystem?.render(canvas);
        game.complexUIRenderSystem.render(canvas);
      },
    );
  };

  // Trigger the one deterministic draw
  dispatcher.scheduleFrame();
}
