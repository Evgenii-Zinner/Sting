import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/components/ui_window.dart';
import 'package:sting/engine/components/ui_button.dart';
import 'package:sting/engine/systems/ui_window_system.dart';

// Dummy Canvas for testing render
class DummyCanvas implements Canvas {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  void drawRRect(RRect rrect, Paint paint) {}
}

void main() {
  group('UIWindowSystem', () {
    late ComponentStorage<UIWindow> windows;
    late ComponentStorage<UIButton> buttons;
    late UIWindowSystem system;

    setUp(() {
      windows = ComponentStorage<UIWindow>(10);
      buttons = ComponentStorage<UIButton>(10);
      system = UIWindowSystem(windows, buttons);
    });

    test('window dragging updates x, y with clamping', () {
      final window = UIWindow.create(
        x: 10.0,
        y: 10.0,
        width: 100.0,
        height: 100.0,
        titleBarHeight: 26.0,
      );
      windows.add(1, window);

      // Pointer down on title bar
      bool handled = system.handlePointerDown(20.0, 20.0);
      expect(handled, isTrue);
      expect(window.isDragging, 1.0);
      expect(window.dragOffsetX, 10.0);
      expect(window.dragOffsetY, 10.0);

      // Move pointer
      system.handlePointerMove(50.0, 50.0,
          screenWidth: 800.0, screenHeight: 600.0);
      expect(window.x, 40.0);
      expect(window.y, 40.0);

      // Clamp test
      system.handlePointerMove(900.0, 700.0,
          screenWidth: 800.0, screenHeight: 600.0);
      expect(window.x, 700.0); // 800 - 100
      expect(window.y, 500.0); // 600 - 100

      // Pointer up
      system.handlePointerUp(900.0, 700.0);
      expect(window.isDragging, 0.0);
    });

    test('button press and click detection', () {
      final button = UIButton.create(
        relativeX: 50.0,
        relativeY: 50.0,
        width: 100.0,
        height: 40.0,
      );
      buttons.add(2, button);

      // Pointer down on button
      bool handled = system.handlePointerDown(60.0, 60.0);
      expect(handled, isTrue);
      expect(button.state, 2.0); // Pressed
      expect(button.wasClicked, 0.0);

      // Pointer up on button
      system.handlePointerUp(60.0, 60.0);
      expect(button.wasClicked, 1.0);
      expect(button.state, 1.0); // Hover

      // Pointer down outside button
      button.wasClicked = 0.0;
      handled = system.handlePointerDown(10.0, 10.0);
      expect(handled, isFalse);
      expect(button.state, 1.0); // Remains hover or whatever it was

      // Move outside
      system.handlePointerMove(10.0, 10.0);
      expect(button.state, 0.0); // Normal
    });

    test('visibility toggle', () {
      final window = UIWindow.create(
        x: 10.0,
        y: 10.0,
        width: 100.0,
        height: 100.0,
      );
      window.isVisible = 0.0;
      windows.add(1, window);

      bool handled = system.handlePointerDown(20.0, 20.0);
      expect(handled, isFalse);
    });

    test('zero-allocation rendering pass (runs without throwing)', () {
      final window = UIWindow.create(
        x: 10.0,
        y: 10.0,
        width: 100.0,
        height: 100.0,
      );
      windows.add(1, window);

      final button = UIButton.create(
        relativeX: 20.0,
        relativeY: 40.0,
        width: 50.0,
        height: 20.0,
      );
      buttons.add(2, button);

      final canvas = DummyCanvas();
      // Should run without throwing errors
      expect(() => system.render(canvas), returnsNormally);
    });
  });
}

void main2() {
  // Just running this as part of main or extending it isn't necessary, but I should add a test for disabled buttons just to be sure.
}
