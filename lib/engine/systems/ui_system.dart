import 'dart:ui';
import 'package:sting/engine/components/ui_bounding_box.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/input_system.dart';
import 'package:sting/engine/renderer.dart';

/// Checks if pointers intersect with UI bounding boxes and updates their state,
/// avoiding allocations per frame by routing pointer IDs directly to components.
class UISystem {
  final ComponentCaste<UIBoundingBox> _uiBoxes;
  final InputSystem _inputSystem;
  final Renderer? _renderer;

  UISystem(this._uiBoxes, this._inputSystem, [this._renderer]);

  /// Updates UI states based on current input.
  void update() {
    // Reset all UI box pointers first
    for (int i = 0; i < _uiBoxes.length; i++) {
      final box = _uiBoxes.getComponentAt(i);
      if (box != null) {
        box.pointerId = -1.0;
      }
    }

    final views = PlatformDispatcher.instance.views;
    final hasView = views.isNotEmpty;
    final physicalSize = hasView ? views.first.physicalSize : Size.zero;

    // Iterate active pointers and find intersections
    for (int p = 0; p < InputSystem.maxPointers; p++) {
      if (_inputSystem.isPointerActive(p)) {
        double px = _inputSystem.getPointerX(p);
        double py = _inputSystem.getPointerY(p);

        if (_renderer != null && hasView && !physicalSize.isEmpty) {
          px = _renderer.mapPointerX(px, physicalSize);
          py = _renderer.mapPointerY(py, physicalSize);
        }

        for (int i = 0; i < _uiBoxes.length; i++) {
          final box = _uiBoxes.getComponentAt(i);
          if (box != null) {
            // Simple AABB vs Point intersection
            if (px >= box.x &&
                px <= box.x + box.width &&
                py >= box.y &&
                py <= box.y + box.height) {
              box.pointerId = p.toDouble();
            }
          }
        }
      }
    }
  }
}
