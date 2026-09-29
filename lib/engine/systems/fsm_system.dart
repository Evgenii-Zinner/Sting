import 'package:sting/engine/components/entity_fsm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';

/// A system that manages state machine transitions and timers.
class FSMSystem {
  final ComponentCaste<EntityFSM> fsmCaste;

  /// Optional rule executed every frame to check if a state should transition.
  /// If it returns a state ID != -1 (or different state), changeState is called.
  /// Callback signature: int transitionRule(int entity, EntityFSM fsm)
  final int Function(int entity, EntityFSM fsm)? transitionRule;

  /// Optional callback executed when an entity enters a new state.
  /// Callback signature: void onStateEnter(int entity, EntityFSM fsm, int previousState, int newState)
  final void Function(int entity, EntityFSM fsm, int previousState, int newState)? onStateEnter;

  /// Optional callback executed when an entity exits its current state.
  /// Callback signature: void onStateExit(int entity, EntityFSM fsm, int currentState, int nextState)
  final void Function(int entity, EntityFSM fsm, int currentState, int nextState)? onStateExit;

  late final Query1<EntityFSM> _query;

  FSMSystem({
    required this.fsmCaste,
    this.transitionRule,
    this.onStateEnter,
    this.onStateExit,
  }) {
    _query = Query1(fsmCaste);
  }

  /// Updates all FSM components by advancing their stateTimer by [dt].
  /// Checks transition rules if provided, and fires enter/exit callbacks.
  void update(double dt) {
    _query.forEach((entity, fsm) {
      // Advance state timer
      fsm.stateTimer += dt;

      // Check transition rule
      if (transitionRule != null) {
        final nextState = transitionRule!(entity, fsm);

        // Ensure state change isn't -1 or identical
        if (nextState != -1 && nextState != fsm.currentState) {
          final currentState = fsm.currentState;

          if (onStateExit != null) {
            onStateExit!(entity, fsm, currentState, nextState);
          }

          fsm.changeState(nextState);

          if (onStateEnter != null) {
            onStateEnter!(entity, fsm, currentState, nextState);
          }
        }
      }
    });
  }
}
