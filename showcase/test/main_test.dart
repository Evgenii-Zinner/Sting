import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/game_state.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';

import '../lib/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bullet Haven Game MVP Setup Tests', () {
    test('Engine initializes correctly with castes registered', () {
      final game = BulletHavenGame();

      // Check that castes exist
      expect(game.scene.getCaste<GameState>('GameState'), isNotNull);
      expect(game.scene.getCaste<Position>('Position'), isNotNull);
      expect(game.scene.getCaste<Velocity>('Velocity'), isNotNull);

      // Check initial state
      expect(game.gameStateSystem.currentState, GameState.stateMenu);
      expect(game.gameStateSystem.shouldUpdateLogic(), false);
    });

    test('startGame transitions state to Playing', () {
      final game = BulletHavenGame();

      game.startGame();

      expect(game.gameStateSystem.currentState, GameState.statePlaying);
      expect(game.gameStateSystem.shouldUpdateLogic(), true);
    });
  });
}
