import 'package:sting/engine/components/game_state.dart';
import 'package:sting/engine/ecs/component_caste.dart';

/// A system to manage high-level game states (Menu, Playing, Paused, GameOver).
///
/// It relies on a singleton entity that holds a [GameState] component.
/// Provides methods to check the current state and transition between states
/// without instantiating any objects during the main loop.
class GameStateSystem {
  final ComponentCaste<GameState> _gameStateCaste;
  final int _globalStateEntityId;

  /// Creates a [GameStateSystem] referencing a [gameStateCaste] and the ID
  /// of the entity holding the global state [globalStateEntityId].
  GameStateSystem(this._gameStateCaste, this._globalStateEntityId) {
    if (_gameStateCaste.get(_globalStateEntityId) == null) {
      // Ensure the global state entity has the component.
      _gameStateCaste.add(
          _globalStateEntityId, GameState.create(GameState.stateMenu));
    }
  }

  /// Gets the current state.
  int get currentState {
    final stateComp = _gameStateCaste.get(_globalStateEntityId);
    if (stateComp != null) {
      return stateComp.state;
    }
    return GameState.stateMenu; // Fallback
  }

  /// Changes the global game state to [newState].
  void changeState(int newState) {
    final stateComp = _gameStateCaste.get(_globalStateEntityId);
    if (stateComp != null) {
      stateComp.state = newState;
    }
  }

  /// Returns `true` if gameplay logic (like movement or physics) should be updated.
  /// Only returns `true` when the current state is [GameState.statePlaying].
  bool shouldUpdateLogic() {
    return currentState == GameState.statePlaying;
  }
}
