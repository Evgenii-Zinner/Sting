import 'dart:math';
import 'package:sting/engine/systems/input_mapping_system.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/virtual_joypad.dart';

/// Reads input from the InputMappingSystem and VirtualJoypad to update the player's Velocity component.
/// Avoids object allocations.
class PlayerInputSystem {
  final InputMappingSystem inputMappingSystem;
  final ComponentCaste<Velocity> velocityCaste;
  final ComponentCaste<VirtualJoypad>? joypadCaste;
  final int joypadEntityId;

  // The entity ID of the player to control.
  int playerEntity = -1;

  // Maximum speed of the player.
  double speed = 150.0;

  PlayerInputSystem({
    required this.inputMappingSystem,
    required this.velocityCaste,
    this.joypadCaste,
    this.joypadEntityId = -1,
  });

  /// Updates the screen center based on the current logical window size.
  void updateScreenSize(double width, double height) {
    // No longer needed for Virtual Joypad but keeping method signature
  }

  /// Sets the player entity to control.
  void setPlayerEntity(int entity) {
    playerEntity = entity;
  }

  /// Updates the player's velocity based on combined input from joypad and keyboard.
  void update() {
    if (playerEntity == -1) return;

    final velocity = velocityCaste.get(playerEntity);
    if (velocity == null) return;

    double inputDx = 0.0;
    double inputDy = 0.0;

    // 1. Read from InputMappingSystem (Keyboard/Gamepad)
    if (inputMappingSystem.isActionActive(GameAction.moveRight)) {
      inputDx += 1.0;
    }
    if (inputMappingSystem.isActionActive(GameAction.moveLeft)) {
      inputDx -= 1.0;
    }
    if (inputMappingSystem.isActionActive(GameAction.moveDown)) {
      inputDy += 1.0;
    }
    if (inputMappingSystem.isActionActive(GameAction.moveUp)) {
      inputDy -= 1.0;
    }

    // 2. Read from VirtualJoypad (Touch)
    if (joypadCaste != null && joypadEntityId != -1) {
      final joypad = joypadCaste!.get(joypadEntityId);
      if (joypad != null) {
        // If joypad is active, it takes precedence or we combine them. Let's combine/override.
        if (joypad.vectorX != 0.0 || joypad.vectorY != 0.0) {
          inputDx = joypad.vectorX;
          inputDy = joypad.vectorY;
        }
      }
    }

    // 3. Normalize vector
    final length = sqrt(inputDx * inputDx + inputDy * inputDy);
    if (length > 0.0) {
      // If combined input is > 1.0 (e.g. from keyboard), normalize it.
      // If from joypad, it might already be normalized, but safe to do it anyway.
      double scale = speed;
      if (length > 1.0) {
        inputDx /= length;
        inputDy /= length;
      } else if (joypadCaste != null && joypadEntityId != -1) {
        // Allow analog partial speed for joypad
        // Length is between 0 and 1
      } else {
        inputDx /= length;
        inputDy /= length;
      }

      velocity.dx = inputDx * speed;
      velocity.dy = inputDy * speed;
    } else {
      velocity.dx = 0.0;
      velocity.dy = 0.0;
    }
  }
}
