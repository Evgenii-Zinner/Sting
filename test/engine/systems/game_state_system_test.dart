import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/game_state.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/game_state_system.dart';

void main() {
  group('GameStateSystem', () {
    late ComponentCaste<GameState> gameStateCaste;
    late GameStateSystem system;
    const globalEntityId = 0;

    setUp(() {
      gameStateCaste = ComponentCaste<GameState>(10);
      system = GameStateSystem(gameStateCaste, globalEntityId);
    });

    test('initializes entity with Menu state if missing', () {
      expect(gameStateCaste.get(globalEntityId), isNotNull);
      expect(system.currentState, GameState.stateMenu);
    });

    test('does not overwrite existing state on initialization', () {
      final existingCaste = ComponentCaste<GameState>(10);
      existingCaste.add(globalEntityId, GameState.create(GameState.statePlaying));

      final existingSystem = GameStateSystem(existingCaste, globalEntityId);
      expect(existingSystem.currentState, GameState.statePlaying);
    });

    test('changes state correctly', () {
      expect(system.currentState, GameState.stateMenu);

      system.changeState(GameState.statePlaying);
      expect(system.currentState, GameState.statePlaying);
      expect(gameStateCaste.get(globalEntityId)!.state, GameState.statePlaying);

      system.changeState(GameState.statePaused);
      expect(system.currentState, GameState.statePaused);
      expect(gameStateCaste.get(globalEntityId)!.state, GameState.statePaused);
    });

    test('shouldUpdateLogic returns true only when Playing', () {
      // Initially Menu
      expect(system.shouldUpdateLogic(), isFalse);

      system.changeState(GameState.statePlaying);
      expect(system.shouldUpdateLogic(), isTrue);

      system.changeState(GameState.statePaused);
      expect(system.shouldUpdateLogic(), isFalse);

      system.changeState(GameState.stateGameOver);
      expect(system.shouldUpdateLogic(), isFalse);
    });
  });
}
