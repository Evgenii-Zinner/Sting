import 'dart:math';

import 'package:sting/engine/components/virtual_joypad.dart';
import 'package:sting/engine/components/ui_bounding_box.dart';
import 'package:sting/engine/components/complex_ui.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/input_system.dart';

/// Handles virtual joypad input, translating touch vectors into normalized values
/// and updating the visual knob UI element.
class VirtualJoypadSystem {
  final ComponentCaste<VirtualJoypad> _joypads;
  final ComponentCaste<UIBoundingBox> _uiBoxes;
  final ComponentCaste<ComplexUI> _complexUIs;
  final InputSystem _inputSystem;

  VirtualJoypadSystem(
    this._joypads,
    this._uiBoxes,
    this._complexUIs,
    this._inputSystem,
  );

  void update() {
    for (int i = 0; i < _joypads.length; i++) {
      final joypadEntity = _joypads.elementAt(i);
      final joypad = _joypads.getComponentAt(i);

      if (joypad == null) continue;

      final boundingBox = _uiBoxes.get(joypadEntity);

      // Handle input
      _processInput(joypad, boundingBox);

      // Update visual knob position
      _updateKnob(joypad);
    }
  }

  void _processInput(VirtualJoypad joypad, UIBoundingBox? boundingBox) {
    if (joypad.activePointerId == -1.0) {
      // Look for a new pointer inside the bounds
      if (boundingBox != null) {
        for (int p = 0; p < InputSystem.maxPointers; p++) {
          if (_inputSystem.isPointerActive(p)) {
            double px = _inputSystem.getPointerX(p);
            double py = _inputSystem.getPointerY(p);

            if (px >= boundingBox.x &&
                px <= boundingBox.x + boundingBox.width &&
                py >= boundingBox.y &&
                py <= boundingBox.y + boundingBox.height) {

              // We found a pointer touching the joypad area, capture it
              joypad.activePointerId = p.toDouble();
              break;
            }
          }
        }
      }
    }

    // Process the active pointer
    if (joypad.activePointerId != -1.0) {
      int pId = joypad.activePointerId.toInt();

      if (!_inputSystem.isPointerActive(pId)) {
        // Pointer released
        joypad.activePointerId = -1.0;
        joypad.vectorX = 0.0;
        joypad.vectorY = 0.0;
      } else {
        // Pointer moved, calculate vector
        double px = _inputSystem.getPointerX(pId);
        double py = _inputSystem.getPointerY(pId);

        double dx = px - joypad.centerX;
        double dy = py - joypad.centerY;
        double distance = sqrt(dx * dx + dy * dy);

        if (distance > joypad.maxRadius) {
          // Clamp to max radius
          double ratio = joypad.maxRadius / distance;
          dx *= ratio;
          dy *= ratio;
          distance = joypad.maxRadius;
        }

        joypad.vectorX = dx / joypad.maxRadius;
        joypad.vectorY = dy / joypad.maxRadius;
      }
    }
  }

  void _updateKnob(VirtualJoypad joypad) {
    if (joypad.knobEntityId != -1.0) {
      int knobId = joypad.knobEntityId.toInt();
      final knobUi = _complexUIs.get(knobId);

      if (knobUi != null) {
        double currentX = joypad.centerX + (joypad.vectorX * joypad.maxRadius);
        double currentY = joypad.centerY + (joypad.vectorY * joypad.maxRadius);

        // Center the knob UI on the coordinates
        knobUi.x = currentX - (knobUi.width / 2.0);
        knobUi.y = currentY - (knobUi.height / 2.0);
      }
    }
  }
}
