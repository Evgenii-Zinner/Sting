import 'dart:math';
import 'package:sting/engine/systems/input_system.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/velocity.dart';

/// Reads input from the InputSystem to update the player's Velocity component.
/// Avoids object allocations.
class PlayerInputSystem {
  final InputSystem inputSystem;
  final ComponentCaste<Velocity> velocityCaste;

  // The entity ID of the player to control.
  int playerEntity = -1;

  // The center of the screen, representing the neutral position of the virtual joystick.
  double screenCenterX = 0.0;
  double screenCenterY = 0.0;

  // Maximum speed of the player.
  double speed = 150.0;

  PlayerInputSystem({
    required this.inputSystem,
    required this.velocityCaste,
  });

  /// Updates the screen center based on the current logical window size.
  void updateScreenSize(double width, double height) {
    screenCenterX = width / 2.0;
    screenCenterY = height / 2.0;
  }

  /// Sets the player entity to control.
  void setPlayerEntity(int entity) {
    playerEntity = entity;
  }

  /// Updates the player's velocity based on current touch input.
  void update() {
    if (playerEntity == -1) return;

    final velocity = velocityCaste.get(playerEntity);
    if (velocity == null) return;

    if (inputSystem.isDown) {
      // Get the first active touch position
      final touchX = inputSystem.x;
      final touchY = inputSystem.y;

      // Calculate direction from center
      final dx = touchX - screenCenterX;
      final dy = touchY - screenCenterY;

      // Calculate length
      final length = sqrt(dx * dx + dy * dy);

      // Add a small deadzone
      if (length > 10.0) {
        // Normalize and scale by speed
        velocity.dx = (dx / length) * speed;
        velocity.dy = (dy / length) * speed;
      } else {
        velocity.dx = 0.0;
        velocity.dy = 0.0;
      }
    } else {
      // No input, stop moving
      velocity.dx = 0.0;
      velocity.dy = 0.0;
    }
  }
}
