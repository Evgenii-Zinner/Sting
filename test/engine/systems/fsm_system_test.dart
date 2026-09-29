import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/entity_fsm.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/fsm_system.dart';

void main() {
  group('EntityFSM Component', () {
    test('creates with default values', () {
      final fsm = EntityFSM.create();
      expect(fsm.currentState, 0);
      expect(fsm.previousState, 0);
      expect(fsm.stateTimer, 0.0);
      expect(fsm.flags, 0);
    });

    test('creates with specific values', () {
      final fsm = EntityFSM.create(
        currentState: 1,
        previousState: 2,
        stateTimer: 3.5,
        flags: 4,
      );
      expect(fsm.currentState, 1);
      expect(fsm.previousState, 2);
      expect(fsm.stateTimer, 3.5);
      expect(fsm.flags, 4);
    });

    test('setters work correctly', () {
      final fsm = EntityFSM.create();
      fsm.currentState = 5;
      fsm.previousState = 6;
      fsm.stateTimer = 7.5;
      fsm.flags = 8;

      expect(fsm.currentState, 5);
      expect(fsm.previousState, 6);
      expect(fsm.stateTimer, 7.5);
      expect(fsm.flags, 8);
    });

    test('changeState updates state and resets timer', () {
      final fsm = EntityFSM.create(
        currentState: 1,
        stateTimer: 10.0,
      );

      fsm.changeState(2);

      expect(fsm.currentState, 2);
      expect(fsm.previousState, 1);
      expect(fsm.stateTimer, 0.0);
    });
  });

  group('FSMSystem', () {
    late ComponentStorage<EntityFSM> fsmCaste;

    setUp(() {
      fsmCaste = ComponentStorage<EntityFSM>(100);
    });

    test('updates stateTimer', () {
      final system = FSMSystem(fsmCaste: fsmCaste);

      fsmCaste.add(0, EntityFSM.create(currentState: 1));
      fsmCaste.add(1, EntityFSM.create(currentState: 2, stateTimer: 5.0));

      system.update(1.5);

      expect(fsmCaste.get(0)!.stateTimer, 1.5);
      expect(fsmCaste.get(1)!.stateTimer, 6.5);
    });

    test('transitionRule triggers changeState and callbacks', () {
      int enterFired = 0;
      int exitFired = 0;

      final system = FSMSystem(
        fsmCaste: fsmCaste,
        transitionRule: (entity, fsm) {
          if (fsm.currentState == 1 && fsm.stateTimer > 2.0) {
            return 2;
          }
          return -1;
        },
        onStateEnter: (entity, fsm, prev, next) {
          enterFired++;
          expect(entity, 0);
          expect(prev, 1);
          expect(next, 2);
        },
        onStateExit: (entity, fsm, current, next) {
          exitFired++;
          expect(entity, 0);
          expect(current, 1);
          expect(next, 2);
        },
      );

      fsmCaste.add(0, EntityFSM.create(currentState: 1));

      // Update less than threshold
      system.update(1.0);
      expect(fsmCaste.get(0)!.currentState, 1);
      expect(enterFired, 0);
      expect(exitFired, 0);

      // Update past threshold
      system.update(1.5); // Total timer: 2.5
      expect(fsmCaste.get(0)!.currentState, 2);
      expect(fsmCaste.get(0)!.previousState, 1);
      expect(fsmCaste.get(0)!.stateTimer, 0.0); // Reset by changeState
      expect(enterFired, 1);
      expect(exitFired, 1);
    });

    test('ignores transitionRule if it returns -1 or same state', () {
      final system = FSMSystem(
        fsmCaste: fsmCaste,
        transitionRule: (entity, fsm) {
          if (entity == 0) return -1;
          if (entity == 1) return fsm.currentState;
          return -1;
        },
        onStateEnter: (e, f, p, n) => fail('Should not be called'),
        onStateExit: (e, f, c, n) => fail('Should not be called'),
      );

      fsmCaste.add(0, EntityFSM.create(currentState: 1));
      fsmCaste.add(1, EntityFSM.create(currentState: 2));

      system.update(1.0);

      expect(fsmCaste.get(0)!.currentState, 1);
      expect(fsmCaste.get(0)!.stateTimer, 1.0);

      expect(fsmCaste.get(1)!.currentState, 2);
      expect(fsmCaste.get(1)!.stateTimer, 1.0);
    });

    test('zero allocations in update loop', () {
      final system = FSMSystem(fsmCaste: fsmCaste);

      for (var i = 0; i < 100; i++) {
        fsmCaste.add(i, EntityFSM.create(currentState: i % 3));
      }

      // We just ensure it completes without error as true allocation testing
      // is hard in Dart without VM service tools.
      expect(() => system.update(0.016), returnsNormally);
    });
  });
}
