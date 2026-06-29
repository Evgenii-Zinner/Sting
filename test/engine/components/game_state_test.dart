import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/game_state.dart';

void main() {
  group('GameState Component', () {
    test('creates with default menu state', () {
      final state = GameState.create();
      expect(state.state, GameState.stateMenu);
    });

    test('creates with given initial state', () {
      final state = GameState.create(GameState.statePlaying);
      expect(state.state, GameState.statePlaying);
    });

    test('updates state successfully', () {
      final state = GameState.create();
      expect(state.state, GameState.stateMenu);

      state.state = GameState.statePaused;
      expect(state.state, GameState.statePaused);
    });

    test('wraps Int32List correctly', () {
      final data = Int32List(1)..[0] = GameState.stateGameOver;
      final state = GameState(data);
      expect(state.state, GameState.stateGameOver);

      state.state = GameState.statePlaying;
      expect(data[0], GameState.statePlaying);
    });
  });
}
