import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/game_state.dart';
import 'package:sting/engine/components/virtual_joypad.dart';
import 'package:sting/engine/components/ui_bounding_box.dart';
import 'package:sting/engine/systems/input_mapping_system.dart';

import '../lib/main.dart';
import '../lib/embedded_assets.dart';
import 'package:sting/engine/assets/asset_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StarSystemGame Integration Test', () {
    tearDown(() {
      final dispatcher = ui.PlatformDispatcher.instance;
      dispatcher.onBeginFrame = null;
      dispatcher.onDrawFrame = null;
      dispatcher.onMetricsChanged = null;
    });

    test('Full integration of components and logic', () async {
      final ui.Image mockAtlas = await AssetLoader.loadEmbeddedImage(
          EmbeddedAssets.assets['atlas.png']!);
      final game = StarSystemGame(mockAtlas);

      // Dispatch metrics
      ui.PlatformDispatcher.instance.onMetricsChanged?.call();

      // Test input
      game.inputMappingSystem.setActionState(GameAction.moveRight, 1.0);
      game.inputMappingSystem.setActionState(GameAction.moveUp, 1.0);
      game.inputMappingSystem.setActionState(GameAction.moveLeft, 1.0);
      game.inputMappingSystem.setActionState(GameAction.moveDown, 1.0);

      // Joypad vector
      final joypad = game.scene
          .getCaste<VirtualJoypad>('VirtualJoypad')
          .get(game.joypadEntityId);
      joypad?.vectorX = 0.5;
      joypad?.vectorY = -0.5;

      // Tick the dispatcher
      ui.PlatformDispatcher.instance.onBeginFrame
          ?.call(const Duration(milliseconds: 16));
      ui.PlatformDispatcher.instance.onDrawFrame?.call();

      // Test ui clicks
      final box = game.scene
          .getCaste<UIBoundingBox>('UIBoundingBox')
          .get(game.spawnPlanetBtnId);
      box?.pointerId = 1.0;
      ui.PlatformDispatcher.instance.onBeginFrame
          ?.call(const Duration(milliseconds: 32));

      box?.pointerId = -1.0;
      ui.PlatformDispatcher.instance.onBeginFrame
          ?.call(const Duration(milliseconds: 48));

      final asteroidBox = game.scene
          .getCaste<UIBoundingBox>('UIBoundingBox')
          .get(game.spawnAsteroidBtnId);
      asteroidBox?.pointerId = 1.0;
      ui.PlatformDispatcher.instance.onBeginFrame
          ?.call(const Duration(milliseconds: 64));
      asteroidBox?.pointerId = -1.0;
      ui.PlatformDispatcher.instance.onBeginFrame
          ?.call(const Duration(milliseconds: 80));

      final cometBox = game.scene
          .getCaste<UIBoundingBox>('UIBoundingBox')
          .get(game.spawnCometBtnId);
      cometBox?.pointerId = 1.0;
      ui.PlatformDispatcher.instance.onBeginFrame
          ?.call(const Duration(milliseconds: 96));
      cometBox?.pointerId = -1.0;
      ui.PlatformDispatcher.instance.onBeginFrame
          ?.call(const Duration(milliseconds: 112));

      game.startGame();
      expect(game.gameStateSystem.currentState, GameState.statePlaying);
    });
  });
}
