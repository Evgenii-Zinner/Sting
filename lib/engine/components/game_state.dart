import 'dart:typed_data';

/// A flat GameState component using a Dart extension type over an Int32List.
/// Index 0: state.
extension type GameState(Int32List data) {
  /// State constant for Menu.
  static const int stateMenu = 0;

  /// State constant for Playing.
  static const int statePlaying = 1;

  /// State constant for Paused.
  static const int statePaused = 2;

  /// State constant for Game Over.
  static const int stateGameOver = 3;

  /// State constant for Level Up.
  static const int stateLevelUp = 4;

  /// Creates a new GameState component with the given [initialState].
  /// Defaults to [stateMenu].
  GameState.create([int initialState = stateMenu]) : this(Int32List(1)..[0] = initialState);

  /// Gets the current state.
  int get state => data[0];

  /// Sets the current state.
  set state(int value) => data[0] = value;
}
