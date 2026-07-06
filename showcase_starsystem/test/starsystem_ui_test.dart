import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/complex_ui.dart';
import 'package:sting/engine/components/ui_bounding_box.dart';

import '../lib/main.dart';
import '../lib/embedded_assets.dart';
import 'package:sting/engine/assets/asset_loader.dart';

void main() {
  test('StarSystemGame UI configures components correctly', () async {
    // 1. Initialize engine
    final Image mockAtlas = await AssetLoader.loadEmbeddedImage(
        EmbeddedAssets.assets['atlas.png']!);
    final game = StarSystemGame(mockAtlas);

    // Initial assertions
    final complexUI = game.scene.getCaste<ComplexUI>('ComplexUI');
    final uiBoxes = game.scene.getCaste<UIBoundingBox>('UIBoundingBox');

    // Check that we have UI components created
    expect(complexUI.length, greaterThan(0));
    expect(uiBoxes.length, greaterThan(0));
  });
}
