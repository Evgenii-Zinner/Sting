import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/ui_bounding_box.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/input_system.dart';
import 'package:sting/engine/systems/ui_system.dart';
import 'package:sting/engine/renderer.dart';

void main() {
  group('UISystem', () {
    late InputSystem inputSystem;
    late ComponentCaste<UIBoundingBox> uiBoxes;
    late UISystem uiSystem;

    setUp(() {
      inputSystem = InputSystem(hook: false);
      uiBoxes = ComponentCaste<UIBoundingBox>(100);
      uiSystem = UISystem(uiBoxes, inputSystem);
    });

    test('updates pointerId to -1 when no pointers are active', () {
      final box = UIBoundingBox.fromBounds(x: 10, y: 10, width: 50, height: 50);
      box.pointerId = 5.0; // Simulate an old pointer
      uiBoxes.add(1, box);

      uiSystem.update();

      expect(box.pointerId, -1.0);
    });

    test('sets pointerId when a pointer intersects', () {
      final box = UIBoundingBox.fromBounds(x: 10, y: 10, width: 50, height: 50);
      uiBoxes.add(1, box);

      // Simulate pointer down inside the box at (20, 20)
      final packet = PointerDataPacket(data: [
        PointerData(
          device: 1,
          change: PointerChange.down,
          physicalX: 20.0,
          physicalY: 20.0,
        )
      ]);
      inputSystem.handlePacket(packet);

      uiSystem.update();

      // Should be assigned slot 0 from InputSystem
      expect(box.pointerId, 0.0);
    });

    test('ignores pointer when outside bounds', () {
      final box = UIBoundingBox.fromBounds(x: 10, y: 10, width: 50, height: 50);
      uiBoxes.add(1, box);

      // Simulate pointer down outside the box at (100, 100)
      final packet = PointerDataPacket(data: [
        PointerData(
          device: 1,
          change: PointerChange.down,
          physicalX: 100.0,
          physicalY: 100.0,
        )
      ]);
      inputSystem.handlePacket(packet);

      uiSystem.update();

      expect(box.pointerId, -1.0);
    });

    test('handles multiple boxes and pointers', () {
      final box1 =
          UIBoundingBox.fromBounds(x: 10, y: 10, width: 50, height: 50);
      final box2 =
          UIBoundingBox.fromBounds(x: 100, y: 100, width: 50, height: 50);
      uiBoxes.add(1, box1);
      uiBoxes.add(2, box2);

      // Simulate two pointers:
      // Device 1 inside box1
      // Device 2 inside box2
      final packet = PointerDataPacket(data: [
        PointerData(
          device: 1,
          change: PointerChange.down,
          physicalX: 20.0,
          physicalY: 20.0,
        ),
        PointerData(
          device: 2,
          change: PointerChange.down,
          physicalX: 120.0,
          physicalY: 120.0,
        )
      ]);
      inputSystem.handlePacket(packet);

      uiSystem.update();

      expect(box1.pointerId, 0.0);
      expect(box2.pointerId, 1.0);
    });

    test('maps physical pointer coordinates to virtual space using Renderer',
        () {
      final renderer = Renderer(
        virtualWidth: 800,
        virtualHeight: 600,
      );
      final mappedUiSystem = UISystem(uiBoxes, inputSystem, renderer);

      final box = UIBoundingBox.fromBounds(x: 10, y: 10, width: 50, height: 50);
      uiBoxes.add(1, box);
      final packet = PointerDataPacket(data: [
        PointerData(
          device: 1,
          change: PointerChange.down,
          physicalX: 40.0,
          physicalY: 40.0,
        )
      ]);
      inputSystem.handlePacket(packet);

      mappedUiSystem.update();
      if (PlatformDispatcher.instance.views.isNotEmpty) {
        final view = PlatformDispatcher.instance.views.first;
        // Let's calculate coords based on the actual physicalSize of the view
        final pSize = view.physicalSize;
        if (!pSize.isEmpty) {
          final rect = renderer.calculateVirtualRect(pSize);
          final scale = rect.width / 800.0;
          // Virtual point (25, 25) which is inside (10, 10, 50, 50)
          final px = rect.left + 25.0 * scale;
          final py = rect.top + 25.0 * scale;

          final testPacket = PointerDataPacket(data: [
            PointerData(
              device: 1,
              change: PointerChange.down,
              physicalX: px,
              physicalY: py,
            )
          ]);
          inputSystem.handlePacket(testPacket);
          mappedUiSystem.update();
          expect(box.pointerId, 0.0);
        }
      }
    });
  });
}
