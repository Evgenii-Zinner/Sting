import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/components/virtual_joypad.dart';
import 'package:sting/engine/components/parallax.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/systems/input_mapping_system.dart';

import '../lib/main.dart';
import '../lib/embedded_assets.dart';
import 'package:sting/engine/assets/asset_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Star System Camera & Parallax Integration', () {
    tearDown(() {
      final dispatcher = ui.PlatformDispatcher.instance;
      dispatcher.onBeginFrame = null;
      dispatcher.onDrawFrame = null;
      dispatcher.onMetricsChanged = null;
    });

    test('Camera moves with InputMappingSystem and updates Parallax', () async {
      final ui.Image mockAtlas = await AssetLoader.loadEmbeddedImage(
          EmbeddedAssets.assets['atlas.png']!);
      final game = StarSystemGame(mockAtlas);

      // Allow systems to initialize metrics
      ui.PlatformDispatcher.instance.onMetricsChanged?.call();

      final viewportComp =
          game.scene.getCaste<Viewport>('Viewport').get(game.cameraEntityId)!;
      double initialX = viewportComp.x;
      double initialY = viewportComp.y;

      // 1. Move Right via InputMappingSystem
      game.inputMappingSystem.setActionState(GameAction.moveRight, 1.0);

      // Tick the dispatcher (1 second simulation for clear movement)
      ui.PlatformDispatcher.instance.onBeginFrame
          ?.call(const Duration(seconds: 1));

      expect(viewportComp.x, greaterThan(initialX));
      expect(viewportComp.y, equals(initialY));

      game.inputMappingSystem.setActionState(GameAction.moveRight, 0.0);

      // 2. Move Down via VirtualJoypad
      final joypad = game.scene
          .getCaste<VirtualJoypad>('VirtualJoypad')
          .get(game.joypadEntityId)!;
      joypad.vectorX = 0.0;
      joypad.vectorY = 1.0;

      initialX = viewportComp.x;
      initialY = viewportComp.y;

      ui.PlatformDispatcher.instance.onBeginFrame
          ?.call(const Duration(seconds: 2));

      expect(viewportComp.x, equals(initialX));
      expect(viewportComp.y, greaterThan(initialY));

      // 3. Verify Parallax Background Position Updated
      // Find the background entity (it has a Parallax component)
      final parallaxCaste = game.scene.getCaste<Parallax>('Parallax');
      final positionCaste = game.scene.getCaste<Position>('Position');

      int bgEntityId = -1;
      for (int i = 0; i < parallaxCaste.length;) {
        bgEntityId = parallaxCaste.elementAt(i);
        break;
      }
      expect(bgEntityId, isNot(-1));

      final bgPosition = positionCaste.get(bgEntityId)!;
      final parallax = parallaxCaste.get(bgEntityId)!;

      expect(
          bgPosition.x,
          closeTo(
              parallax.basePositionX +
                  (viewportComp.x * (1.0 - parallax.scrollFactorX)),
              0.01));
      expect(
          bgPosition.y,
          closeTo(
              parallax.basePositionY +
                  (viewportComp.y * (1.0 - parallax.scrollFactorY)),
              0.01));
    });
  });
}
