import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/virtual_joypad.dart';
import 'package:sting/engine/components/ui_bounding_box.dart';
import 'package:sting/engine/components/complex_ui.dart';
import 'package:sting/engine/systems/virtual_joypad_system.dart';
import 'package:sting/engine/systems/input_system.dart';

void main() {
  group('VirtualJoypadSystem', () {
    late Swarm swarm;
    late ComponentCaste<VirtualJoypad> joypads;
    late ComponentCaste<UIBoundingBox> uiBoxes;
    late ComponentCaste<ComplexUI> complexUIs;
    late InputSystem inputSystem;
    late VirtualJoypadSystem system;

    setUp(() {
      swarm = Swarm();
      joypads = ComponentCaste<VirtualJoypad>(10);
      uiBoxes = ComponentCaste<UIBoundingBox>(10);
      complexUIs = ComponentCaste<ComplexUI>(10);
      inputSystem = InputSystem(hook: false);

      system = VirtualJoypadSystem(joypads, uiBoxes, complexUIs, inputSystem);
    });

    test('captures pointer on down inside bounds', () {
      final joypadEntity = swarm.createEntity();
      final joypad = VirtualJoypad.create(maxRadius: 50.0, centerX: 50.0, centerY: 50.0);
      final box = UIBoundingBox.fromBounds(x: 0, y: 0, width: 100, height: 100);

      joypads.add(joypadEntity, joypad);
      uiBoxes.add(joypadEntity, box);

      // Simulate pointer down inside box
      final packet = PointerDataPacket(data: [
        PointerData(
          device: 1,
          change: PointerChange.down,
          physicalX: 50.0,
          physicalY: 50.0,
        )
      ]);
      inputSystem.handlePacket(packet);

      system.update();

      expect(joypad.activePointerId, 0.0);
      expect(joypad.vectorX, 0.0);
      expect(joypad.vectorY, 0.0);
    });

    test('updates vector when pointer moves', () {
      final joypadEntity = swarm.createEntity();
      final joypad = VirtualJoypad.create(maxRadius: 50.0, centerX: 50.0, centerY: 50.0);
      final box = UIBoundingBox.fromBounds(x: 0, y: 0, width: 100, height: 100);

      joypads.add(joypadEntity, joypad);
      uiBoxes.add(joypadEntity, box);

      // Capture first
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(device: 1, change: PointerChange.down, physicalX: 50.0, physicalY: 50.0)
      ]));
      system.update();
      expect(joypad.activePointerId, 0.0);

      // Move to right
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(device: 1, change: PointerChange.move, physicalX: 75.0, physicalY: 50.0)
      ]));
      system.update();

      expect(joypad.vectorX, 0.5);
      expect(joypad.vectorY, 0.0);
    });

    test('clamps vector and position to max radius', () {
      final joypadEntity = swarm.createEntity();
      final joypad = VirtualJoypad.create(maxRadius: 50.0, centerX: 50.0, centerY: 50.0);
      final box = UIBoundingBox.fromBounds(x: 0, y: 0, width: 100, height: 100);

      joypads.add(joypadEntity, joypad);
      uiBoxes.add(joypadEntity, box);

      // Capture first
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(device: 1, change: PointerChange.down, physicalX: 50.0, physicalY: 50.0)
      ]));
      system.update();

      // Move way out to right (distance 100, maxRadius is 50)
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(device: 1, change: PointerChange.move, physicalX: 150.0, physicalY: 50.0)
      ]));
      system.update();

      expect(joypad.vectorX, 1.0); // Clamped
      expect(joypad.vectorY, 0.0);
    });

    test('updates knob UI position', () {
      final joypadEntity = swarm.createEntity();
      final knobEntity = swarm.createEntity();

      final joypad = VirtualJoypad.create(
        maxRadius: 50.0,
        centerX: 50.0,
        centerY: 50.0,
        knobEntityId: knobEntity.toDouble(),
      );
      final box = UIBoundingBox.fromBounds(x: 0, y: 0, width: 100, height: 100);
      final knobUi = ComplexUI(x: 0, y: 0, width: 20, height: 20); // 20x20 knob

      joypads.add(joypadEntity, joypad);
      uiBoxes.add(joypadEntity, box);
      complexUIs.add(knobEntity, knobUi);

      // Capture first
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(device: 1, change: PointerChange.down, physicalX: 50.0, physicalY: 50.0)
      ]));
      system.update();

      // Move knob up and right
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(device: 1, change: PointerChange.move, physicalX: 100.0, physicalY: 0.0)
      ]));
      system.update();

      // Vector should be maxed diagonally (distance > 50)
      // dx = 50, dy = -50
      // normalized dx = 50 / sqrt(50^2 + -50^2) = 0.707
      expect(joypad.vectorX, closeTo(0.707, 0.01));
      expect(joypad.vectorY, closeTo(-0.707, 0.01));

      // Knob X = centerX + (vectorX * maxRadius) - (width/2)
      // Knob X = 50 + (0.707 * 50) - 10 = 50 + 35.35 - 10 = 75.35
      expect(knobUi.x, closeTo(75.35, 0.01));
      expect(knobUi.y, closeTo(4.64, 0.01));
    });

    test('releases pointer on up', () {
      final joypadEntity = swarm.createEntity();
      final joypad = VirtualJoypad.create(maxRadius: 50.0, centerX: 50.0, centerY: 50.0);
      final box = UIBoundingBox.fromBounds(x: 0, y: 0, width: 100, height: 100);

      joypads.add(joypadEntity, joypad);
      uiBoxes.add(joypadEntity, box);

      // Capture
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(device: 1, change: PointerChange.down, physicalX: 50.0, physicalY: 50.0)
      ]));
      system.update();
      expect(joypad.activePointerId, 0.0);

      // Move
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(device: 1, change: PointerChange.move, physicalX: 75.0, physicalY: 50.0)
      ]));
      system.update();
      expect(joypad.vectorX, 0.5);

      // Release
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(device: 1, change: PointerChange.up, physicalX: 75.0, physicalY: 50.0)
      ]));
      system.update();

      expect(joypad.activePointerId, -1.0);
      expect(joypad.vectorX, 0.0);
      expect(joypad.vectorY, 0.0);
    });
  });
}
