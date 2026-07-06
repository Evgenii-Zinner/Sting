import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/systems/input_system.dart';
import 'package:sting/engine/systems/input_mapping_system.dart';

void main() {
  group('InputMappingSystem', () {
    late InputSystem pointerSystem;
    late InputMappingSystem mappingSystem;

    setUp(() {
      pointerSystem = InputSystem(hook: false);
      mappingSystem = InputMappingSystem(pointerSystem, hook: false);
    });

    test('bindKey and keyboard input update action state', () {
      mappingSystem.bindKey(119, GameAction.moveUp); // e.g. W key

      expect(mappingSystem.getActionValue(GameAction.moveUp), 0.0);
      expect(mappingSystem.isActionActive(GameAction.moveUp), isFalse);

      final downEvent = const KeyData(
        type: KeyEventType.down,
        physical: 1,
        logical: 119,
        timeStamp: Duration.zero,
        character: 'w',
        synthesized: false,
      );

      mappingSystem.handleKeyData(downEvent);

      expect(mappingSystem.getActionValue(GameAction.moveUp), 1.0);
      expect(mappingSystem.isActionActive(GameAction.moveUp), isTrue);
      expect(mappingSystem.activeSource, InputSource.keyboard);

      final upEvent = const KeyData(
        type: KeyEventType.up,
        physical: 1,
        logical: 119,
        timeStamp: Duration.zero,
        character: 'w',
        synthesized: false,
      );

      mappingSystem.handleKeyData(upEvent);

      expect(mappingSystem.getActionValue(GameAction.moveUp), 0.0);
      expect(mappingSystem.isActionActive(GameAction.moveUp), isFalse);
    });

    test('pointer input updates active source', () {
      expect(mappingSystem.activeSource, InputSource.unknown);

      final mouseEvent = PointerDataPacket(
        data: [
          PointerData(
            change: PointerChange.down,
            kind: PointerDeviceKind.mouse,
          ),
        ],
      );

      mappingSystem.handlePointerDataPacket(mouseEvent);
      expect(mappingSystem.activeSource, InputSource.mouse);

      final touchEvent = PointerDataPacket(
        data: [
          PointerData(
            change: PointerChange.down,
            kind: PointerDeviceKind.touch,
          ),
        ],
      );

      mappingSystem.handlePointerDataPacket(touchEvent);
      expect(mappingSystem.activeSource, InputSource.touch);
    });

    test('setActionState manually sets action value', () {
      mappingSystem.setActionState(GameAction.moveRight, 0.75);

      expect(mappingSystem.getActionValue(GameAction.moveRight), 0.75);
      expect(mappingSystem.isActionActive(GameAction.moveRight), isTrue);
    });

    test(
        'handleKeyData handles repeat events and returns handled status correctly',
        () {
      mappingSystem.bindKey(100, GameAction.moveRight); // D key

      final downEvent = const KeyData(
        type: KeyEventType.down,
        physical: 1,
        logical: 100,
        character: '',
        synthesized: false,
        timeStamp: Duration.zero,
      );
      expect(mappingSystem.handleKeyData(downEvent), isTrue);
      expect(mappingSystem.getActionValue(GameAction.moveRight), 1.0);

      final repeatEvent = const KeyData(
        type: KeyEventType.repeat,
        physical: 1,
        logical: 100,
        character: '',
        synthesized: false,
        timeStamp: Duration.zero,
      );
      expect(mappingSystem.handleKeyData(repeatEvent), isTrue);
      expect(mappingSystem.getActionValue(GameAction.moveRight), 1.0);

      // Verify that repeat events on an inactive/bound key do NOT activate it
      mappingSystem.bindKey(200, GameAction.moveLeft);
      final repeatInactiveEvent = const KeyData(
        type: KeyEventType.repeat,
        physical: 1,
        logical: 200,
        character: '',
        synthesized: false,
        timeStamp: Duration.zero,
      );
      expect(mappingSystem.handleKeyData(repeatInactiveEvent), isTrue);
      expect(mappingSystem.getActionValue(GameAction.moveLeft),
          0.0); // Remains inactive

      final unboundEvent = const KeyData(
        type: KeyEventType.down,
        physical: 1,
        logical: 999,
        character: '',
        synthesized: false,
        timeStamp: Duration.zero,
      );
      expect(mappingSystem.handleKeyData(unboundEvent), isFalse);
    });
  });
}
