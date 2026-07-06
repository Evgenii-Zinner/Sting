import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/systems/input_system.dart';

void main() {
  group('InputSystem', () {
    late InputSystem inputSystem;

    setUp(() {
      inputSystem = InputSystem(hook: false);
    });

    test('Initial state is empty', () {
      expect(inputSystem.activePointerCount, 0);
      expect(inputSystem.isDown, false);
      expect(inputSystem.x, 0.0);
      expect(inputSystem.y, 0.0);
    });

    test('Tracks pointer down event', () {
      final packet = PointerDataPacket(data: [
        PointerData(
          change: PointerChange.down,
          device: 1,
          physicalX: 100.0,
          physicalY: 200.0,
        )
      ]);

      inputSystem.handlePacket(packet);

      expect(inputSystem.activePointerCount, 1);
      expect(inputSystem.isDown, true);
      expect(inputSystem.x, 100.0);
      expect(inputSystem.y, 200.0);
      expect(inputSystem.isPointerActive(0), true);
      expect(inputSystem.getPointerX(0), 100.0);
      expect(inputSystem.getPointerY(0), 200.0);
    });

    test('Tracks pointer move event', () {
      // First, down
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(
          change: PointerChange.down,
          device: 1,
          physicalX: 100.0,
          physicalY: 200.0,
        )
      ]));

      // Then, move
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(
          change: PointerChange.move,
          device: 1,
          physicalX: 150.0,
          physicalY: 250.0,
        )
      ]));

      expect(inputSystem.activePointerCount, 1);
      expect(inputSystem.isDown, true);
      expect(inputSystem.x, 150.0);
      expect(inputSystem.y, 250.0);
    });

    test('Tracks pointer up event', () {
      // First, down
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(
          change: PointerChange.down,
          device: 1,
          physicalX: 100.0,
          physicalY: 200.0,
        )
      ]));

      // Then, up
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(
          change: PointerChange.up,
          device: 1,
          physicalX: 100.0,
          physicalY: 200.0,
        )
      ]));

      expect(inputSystem.activePointerCount, 0);
      expect(inputSystem.isDown, false);
      expect(inputSystem.isPointerActive(0), false);
    });

    test('Tracks pointer cancel event', () {
      // First, down
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(
          change: PointerChange.down,
          device: 1,
          physicalX: 100.0,
          physicalY: 200.0,
        )
      ]));

      // Then, cancel
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(
          change: PointerChange.cancel,
          device: 1,
          physicalX: 100.0,
          physicalY: 200.0,
        )
      ]));

      expect(inputSystem.activePointerCount, 0);
      expect(inputSystem.isDown, false);
      expect(inputSystem.isPointerActive(0), false);
    });

    test('Tracks multiple pointers', () {
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(
          change: PointerChange.down,
          device: 1,
          physicalX: 10.0,
          physicalY: 20.0,
        ),
        PointerData(
          change: PointerChange.down,
          device: 2,
          physicalX: 30.0,
          physicalY: 40.0,
        )
      ]));

      expect(inputSystem.activePointerCount, 2);
      expect(inputSystem.isDown, true);

      expect(inputSystem.isPointerActive(0), true);
      expect(inputSystem.getPointerX(0), 10.0);
      expect(inputSystem.getPointerY(0), 20.0);

      expect(inputSystem.isPointerActive(1), true);
      expect(inputSystem.getPointerX(1), 30.0);
      expect(inputSystem.getPointerY(1), 40.0);
    });

    test('Ignores extra pointers beyond maxPointers', () {
      List<PointerData> data = [];
      for (int i = 0; i < InputSystem.maxPointers + 5; i++) {
        data.add(PointerData(
          change: PointerChange.down,
          device: i,
          physicalX: i * 10.0,
          physicalY: i * 10.0,
        ));
      }

      inputSystem.handlePacket(PointerDataPacket(data: data));

      expect(inputSystem.activePointerCount, InputSystem.maxPointers);
    });

    test('Boundary checks on invalid index returns default values', () {
      expect(inputSystem.isPointerActive(-1), false);
      expect(inputSystem.isPointerActive(InputSystem.maxPointers), false);
      expect(inputSystem.getPointerX(-1), 0.0);
      expect(inputSystem.getPointerX(InputSystem.maxPointers), 0.0);
      expect(inputSystem.getPointerY(-1), 0.0);
      expect(inputSystem.getPointerY(InputSystem.maxPointers), 0.0);
    });

    test('Hooks correctly into PlatformDispatcher', () {
      final oldHook = PlatformDispatcher.instance.onPointerDataPacket;
      try {
        final hookedSystem = InputSystem(hook: true);
        expect(PlatformDispatcher.instance.onPointerDataPacket, isNotNull);
        hookedSystem.dispose();
        expect(PlatformDispatcher.instance.onPointerDataPacket, isNull);
      } finally {
        // Restore hook just in case for other tests
        PlatformDispatcher.instance.onPointerDataPacket = oldHook;
      }
    });

    test('Forwards pointer packets to the original dispatcher handler', () {
      bool originalCalled = false;
      void mockOriginalHandler(PointerDataPacket packet) {
        originalCalled = true;
      }

      final oldHook = PlatformDispatcher.instance.onPointerDataPacket;
      PlatformDispatcher.instance.onPointerDataPacket = mockOriginalHandler;

      try {
        final hookedSystem = InputSystem(hook: true);

        final testPacket = PointerDataPacket(data: [
          PointerData(
              change: PointerChange.down,
              device: 1,
              physicalX: 5.0,
              physicalY: 5.0)
        ]);

        PlatformDispatcher.instance.onPointerDataPacket?.call(testPacket);

        expect(originalCalled, isTrue);
        hookedSystem.dispose();
      } finally {
        PlatformDispatcher.instance.onPointerDataPacket = oldHook;
      }
    });
  });
}
