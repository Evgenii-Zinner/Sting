import 'dart:typed_data';
import 'dart:ui';

/// Translates raw PointerDataPacket events into internal flat array tracking
/// without allocating new objects per event, adhering to the engine's zero-allocation constraint.
class InputSystem {
  // Maximum number of simultaneous pointers to track
  static const int maxPointers = 16;

  // Track pointer coordinates
  final Float32List _xCoords = Float32List(maxPointers);
  final Float32List _yCoords = Float32List(maxPointers);

  // Track pointer IDs (devices)
  // using -1 to indicate an unused slot
  final Int32List _deviceIds = Int32List(maxPointers)..fillRange(0, maxPointers, -1);

  // Track pointer state (0 = up/inactive, 1 = down/active)
  final Uint8List _states = Uint8List(maxPointers);

  /// Initialize the system and optionally hook into the PlatformDispatcher.
  /// Set [hook] to false for testing.
  InputSystem({bool hook = true}) {
    if (hook) {
      PlatformDispatcher.instance.onPointerDataPacket = _handlePointerDataPacket;
    }
  }

  /// Get the current number of active pointers
  int get activePointerCount {
    int count = 0;
    for (int i = 0; i < maxPointers; i++) {
      if (_states[i] == 1) count++;
    }
    return count;
  }

  /// Handle raw pointer data packets from the engine.
  void _handlePointerDataPacket(PointerDataPacket packet) {
    for (final data in packet.data) {
      if (data.change == PointerChange.add || data.change == PointerChange.down) {
        // Allocate slot on add or down
        int slot = _allocateSlot(data.device);
        if (slot != -1) {
          _xCoords[slot] = data.physicalX;
          _yCoords[slot] = data.physicalY;
          if (data.change == PointerChange.down) {
            _states[slot] = 1;
          }
        }
      } else if (data.change == PointerChange.move) {
        int slot = _getExistingSlot(data.device);
        if (slot != -1) {
          _xCoords[slot] = data.physicalX;
          _yCoords[slot] = data.physicalY;
          _states[slot] = 1;
        }
      } else if (data.change == PointerChange.up || data.change == PointerChange.cancel) {
        int slot = _getExistingSlot(data.device);
        if (slot != -1) {
          // Mark as inactive but keep the slot until remove
          _states[slot] = 0;
        }
      } else if (data.change == PointerChange.remove) {
        int slot = _getExistingSlot(data.device);
        if (slot != -1) {
          _states[slot] = 0;
          _deviceIds[slot] = -1; // Free the slot
        }
      }
    }
  }

  /// For manual input testing, simulates receiving a pointer packet
  void handlePacket(PointerDataPacket packet) {
    _handlePointerDataPacket(packet);
  }

  /// Find an existing slot for a device ID
  int _getExistingSlot(int deviceId) {
    for (int i = 0; i < maxPointers; i++) {
      if (_deviceIds[i] == deviceId) {
        return i;
      }
    }
    return -1;
  }

  /// Allocate a new slot for a device ID if not already present
  int _allocateSlot(int deviceId) {
    // Check if it already has a slot
    int existingSlot = _getExistingSlot(deviceId);
    if (existingSlot != -1) return existingSlot;

    // Find first empty slot
    for (int i = 0; i < maxPointers; i++) {
      if (_deviceIds[i] == -1) {
        _deviceIds[i] = deviceId;
        return i;
      }
    }

    // Drop the input if we run out of pointer slots
    return -1;
  }

  /// Check if a specific pointer (by index 0 to maxPointers-1) is active
  bool isPointerActive(int index) {
    if (index < 0 || index >= maxPointers) return false;
    return _states[index] == 1;
  }

  /// Get the X coordinate of a specific pointer index
  double getPointerX(int index) {
    if (index < 0 || index >= maxPointers) return 0.0;
    return _xCoords[index];
  }

  /// Get the Y coordinate of a specific pointer index
  double getPointerY(int index) {
    if (index < 0 || index >= maxPointers) return 0.0;
    return _yCoords[index];
  }

  /// Gets the first active pointer's X coordinate, or 0.0 if none
  double get x {
    for (int i = 0; i < maxPointers; i++) {
      if (_states[i] == 1) return _xCoords[i];
    }
    return 0.0;
  }

  /// Gets the first active pointer's Y coordinate, or 0.0 if none
  double get y {
    for (int i = 0; i < maxPointers; i++) {
      if (_states[i] == 1) return _yCoords[i];
    }
    return 0.0;
  }

  /// Check if there's any active pointer
  bool get isDown {
    return activePointerCount > 0;
  }

  /// Clean up the hook
  void dispose() {
    PlatformDispatcher.instance.onPointerDataPacket = null;
  }
}
