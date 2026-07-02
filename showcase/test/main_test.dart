import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:sting/engine/components/game_state.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';

import '../lib/main.dart';

class MockImage implements ui.Image {
  @override
  int get width => 100;
  @override
  int get height => 100;
  @override
  void dispose() {}
  @override
  Future<ByteData?> toByteData({ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) async => null;
  @override
  ui.ColorSpace get colorSpace => ui.ColorSpace.sRGB;
  @override
  bool get debugDisposed => false;
  @override
  MockImage clone() => this;
  @override
  bool get isCloneOfBase => false;
  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() => null;
  @override
  bool isCloneOf(ui.Image other) => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bullet Haven Game MVP Setup Tests', () {
    test('Engine initializes correctly with castes registered', () {
      final mockImage = MockImage();
      final game = BulletHavenGame(mockImage);

      // Check that castes exist
      expect(game.scene.getCaste<GameState>('GameState'), isNotNull);
      expect(game.scene.getCaste<Position>('Position'), isNotNull);
      expect(game.scene.getCaste<Velocity>('Velocity'), isNotNull);

      // Check initial state
      // Modified to test statePlaying as the default state has been updated to Playing for MVP showcase logic
      expect(game.gameStateSystem.currentState, GameState.statePlaying);
      expect(game.gameStateSystem.shouldUpdateLogic(), true);
    });

    test('startGame transitions state to Playing', () {
      final mockImage = MockImage();
      final game = BulletHavenGame(mockImage);

      game.startGame();

      expect(game.gameStateSystem.currentState, GameState.statePlaying);
      expect(game.gameStateSystem.shouldUpdateLogic(), true);
    });
  });
}
