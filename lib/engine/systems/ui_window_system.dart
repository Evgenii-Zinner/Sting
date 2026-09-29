import 'dart:ui';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/components/ui_window.dart';
import 'package:sting/engine/components/ui_button.dart';

class UIWindowSystem {
  final ComponentStorage<UIWindow> windows;
  final ComponentStorage<UIButton> buttons;

  final Paint _windowBgPaint = Paint()..style = PaintingStyle.fill;
  final Paint _titleBarBgPaint = Paint()..style = PaintingStyle.fill;
  final Paint _borderPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _buttonPaint = Paint()..style = PaintingStyle.fill;
  final Paint _buttonBorderPaint = Paint()..style = PaintingStyle.stroke;

  int _draggedWindow = -1;

  UIWindowSystem(this.windows, this.buttons);

  bool handlePointerDown(double px, double py) {
    bool handled = false;

    // Check windows (reverse order for top-most first)
    for (int i = windows.length - 1; i >= 0; i--) {
      final window = windows.getAt(i);
      final entity = windows.entityAt(i);
      if (window.isVisible == 0.0) continue;

      // Check title bar hit
      if (px >= window.x &&
          px <= window.x + window.width &&
          py >= window.y &&
          py <= window.y + window.titleBarHeight) {
        window.isDragging = 1.0;
        window.dragOffsetX = px - window.x;
        window.dragOffsetY = py - window.y;
        _draggedWindow = entity;
        handled = true;
        break; // Only interact with top-most valid hit
      }
    }

    if (handled) return true; // prevent click-through to buttons below a dragged window

    // Now check buttons
    for (int i = 0; i < buttons.length; i++) {
      final button = buttons.getAt(i);
      final bx = button.relativeX;
      final by = button.relativeY;

      if (button.state == 3.0) continue; // skip disabled buttons

      if (px >= bx &&
          px <= bx + button.width &&
          py >= by &&
          py <= by + button.height) {
        button.state = 2.0; // Pressed
        button.wasClicked = 0.0;
        handled = true;
      }
    }

    return handled;
  }

  void handlePointerMove(double px, double py, {double screenWidth = 10000.0, double screenHeight = 10000.0}) {
    if (_draggedWindow != -1) {
      final window = windows.get(_draggedWindow);
      if (window != null && window.isDragging == 1.0) {
        double newX = px - window.dragOffsetX;
        double newY = py - window.dragOffsetY;

        // Clamp to screen
        if (newX < 0) newX = 0;
        if (newY < 0) newY = 0;
        if (newX + window.width > screenWidth) newX = screenWidth - window.width;
        if (newY + window.height > screenHeight) newY = screenHeight - window.height;

        window.x = newX;
        window.y = newY;
      }
    }

    // Update button hover states
    for (int i = 0; i < buttons.length; i++) {
      final button = buttons.getAt(i);
      final bx = button.relativeX;
      final by = button.relativeY;

      if (button.state == 2.0) continue; // Don't override pressed state

      if (px >= bx &&
          px <= bx + button.width &&
          py >= by &&
          py <= by + button.height) {
        if (button.state != 3.0) { // Not disabled
          button.state = 1.0; // Hovered
        }
      } else {
        if (button.state != 3.0) {
          button.state = 0.0; // Normal
        }
      }
    }
  }

  void handlePointerUp(double px, double py) {
    if (_draggedWindow != -1) {
      final window = windows.get(_draggedWindow);
      if (window != null) {
        window.isDragging = 0.0;
      }
      _draggedWindow = -1;
    }

    for (int i = 0; i < buttons.length; i++) {
      final button = buttons.getAt(i);
      final bx = button.relativeX;
      final by = button.relativeY;

      if (button.state == 2.0) { // Was pressed
        if (px >= bx &&
            px <= bx + button.width &&
            py >= by &&
            py <= by + button.height) {
          button.wasClicked = 1.0;
          button.state = 1.0; // Hover
        } else {
          button.state = 0.0; // Normal
        }
      }
    }
  }

  void render(Canvas canvas) {
    for (int i = 0; i < windows.length; i++) {
      final window = windows.getAt(i);
      if (window.isVisible == 0.0) continue;

      // Background
      _windowBgPaint.color = Color(window.backgroundColorHex.toInt());
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(window.x, window.y, window.width, window.height),
          Radius.circular(window.borderRadius)
        ),
        _windowBgPaint
      );

      // Title Bar
      _titleBarBgPaint.color = Color(window.titleBarColorHex.toInt());
      // Only rounded top corners for title bar
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(window.x, window.y, window.width, window.titleBarHeight),
          topLeft: Radius.circular(window.borderRadius),
          topRight: Radius.circular(window.borderRadius),
        ),
        _titleBarBgPaint
      );

      // Border
      _borderPaint.color = Color(window.borderColorHex.toInt());
      _borderPaint.strokeWidth = window.borderWidth;
      // If glowing border is requested, we can simulate via elevation or shadow, but zero-allocation means we avoid new Paint objects.
      // Just drawing the border.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(window.x, window.y, window.width, window.height),
          Radius.circular(window.borderRadius)
        ),
        _borderPaint
      );
    }

    for (int i = 0; i < buttons.length; i++) {
      final button = buttons.getAt(i);
      final state = button.state;

      int colorHex = button.normalColorHex.toInt();
      if (state == 1.0) colorHex = button.hoverColorHex.toInt();
      if (state == 2.0) colorHex = button.pressedColorHex.toInt();
      if (state == 3.0) colorHex = 0xFF555555; // Default disabled color (grey)

      _buttonPaint.color = Color(colorHex);
      final rect = Rect.fromLTWH(button.relativeX, button.relativeY, button.width, button.height);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(button.borderRadius));

      canvas.drawRRect(rrect, _buttonPaint);

      if (button.borderWidth > 0) {
        _buttonBorderPaint.color = Color(button.borderColorHex.toInt());
        _buttonBorderPaint.strokeWidth = button.borderWidth;
        canvas.drawRRect(rrect, _buttonBorderPaint);
      }
    }
  }
}
