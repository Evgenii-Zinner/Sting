import 'dart:typed_data';
import 'dart:ui';

import 'input_system.dart';

enum InputSource { unknown, touch, mouse, keyboard, gamepad }

/// Abstract representation of Game Actions
class GameAction {
  static const int moveUp = 0;
  static const int moveDown = 1;
  static const int moveLeft = 2;
  static const int moveRight = 3;
  static const int fire = 4;
  static const int jump = 5;
  static const int pause = 6;
  static const int maxActions = 16; // Arbitrary max for array sizes
}

/// Maps physical input (Keyboard, Mouse, Touch, Gamepad) to abstract actions.
class InputMappingSystem {
  final InputSystem _pointerSystem;

  // Track state of mapped actions
  // Using Float32List to represent analog values (0.0 to 1.0 or -1.0 to 1.0)
  final Float32List _actionStates = Float32List(GameAction.maxActions);

  // Keyboard mapping: logicalKeyId -> actionId
  static const int maxKeyBindings = 32;
  final List<int> _keyBindingKeys = List<int>.filled(maxKeyBindings, 0);
  final Int32List _keyBindingActions = Int32List(maxKeyBindings)
    ..fillRange(0, maxKeyBindings, -1);
  int _keyBindingCount = 0;

  // Track active keys
  final List<int> _activeKeys = List<int>.filled(16, 0);

  InputSource _activeSource = InputSource.unknown;

  final bool Function(KeyData)? _originalKeyHandler;
  final void Function(PointerDataPacket)? _originalPointerHandler;

  InputMappingSystem(this._pointerSystem, {bool hook = true})
      : _originalKeyHandler =
            hook ? PlatformDispatcher.instance.onKeyData : null,
        _originalPointerHandler =
            hook ? PlatformDispatcher.instance.onPointerDataPacket : null {
    if (hook) {
      PlatformDispatcher.instance.onKeyData = (data) {
        final handled = _handleKeyData(data);
        if (_originalKeyHandler != null) {
          return _originalKeyHandler(data) || handled;
        }
        return handled;
      };

      PlatformDispatcher.instance.onPointerDataPacket = (packet) {
        _handlePointerDataPacket(packet);

        if (_originalPointerHandler != null) {
          _originalPointerHandler(packet);
        } else {
          // Forward to the underlying InputSystem only if it wasn't already hooked
          _pointerSystem.handlePacket(packet);
        }
      };
    }
  }

  void bindKey(int logicalKeyId, int actionId) {
    if (_keyBindingCount < maxKeyBindings) {
      _keyBindingKeys[_keyBindingCount] = logicalKeyId;
      _keyBindingActions[_keyBindingCount] = actionId;
      _keyBindingCount++;
    }
  }

  bool _handleKeyData(KeyData data) {
    _activeSource = InputSource.keyboard;

    bool isBound = false;
    for (int i = 0; i < _keyBindingCount; i++) {
      if (_keyBindingKeys[i] == data.logical) {
        isBound = true;
        break;
      }
    }

    if (data.type == KeyEventType.down) {
      _setKeyDown(data.logical);
      _updateMappedAction(data.logical, 1.0);
    } else if (data.type == KeyEventType.up) {
      _setKeyUp(data.logical);
      _updateMappedAction(data.logical, 0.0);
    }

    return isBound;
  }

  void _handlePointerDataPacket(PointerDataPacket packet) {
    for (final data in packet.data) {
      if (data.change == PointerChange.down ||
          data.change == PointerChange.move) {
        if (data.kind == PointerDeviceKind.mouse) {
          _activeSource = InputSource.mouse;
        } else if (data.kind == PointerDeviceKind.touch) {
          _activeSource = InputSource.touch;
        }
      }
    }
  }

  // For testing
  bool handleKeyData(KeyData data) {
    return _handleKeyData(data);
  }

  void handlePointerDataPacket(PointerDataPacket packet) {
    _handlePointerDataPacket(packet);
  }

  void _setKeyDown(int logicalKey) {
    for (int i = 0; i < _activeKeys.length; i++) {
      if (_activeKeys[i] == logicalKey) return; // already active
      if (_activeKeys[i] == 0) {
        _activeKeys[i] = logicalKey;
        return;
      }
    }
  }

  void _setKeyUp(int logicalKey) {
    for (int i = 0; i < _activeKeys.length; i++) {
      if (_activeKeys[i] == logicalKey) {
        _activeKeys[i] = 0;
        return;
      }
    }
  }

  void _updateMappedAction(int logicalKey, double value) {
    for (int i = 0; i < _keyBindingCount; i++) {
      if (_keyBindingKeys[i] == logicalKey) {
        int actionId = _keyBindingActions[i];
        if (actionId >= 0 && actionId < GameAction.maxActions) {
          if (value == 0.0) {
            // Check if any other key bound to this action is still active
            bool stillActive = false;
            for (int j = 0; j < _keyBindingCount; j++) {
              if (_keyBindingActions[j] == actionId &&
                  _isKeyActive(_keyBindingKeys[j])) {
                stillActive = true;
                break;
              }
            }
            if (!stillActive) {
              _actionStates[actionId] = value;
            }
          } else {
            _actionStates[actionId] = value;
          }
        }
      }
    }
  }

  bool _isKeyActive(int logicalKey) {
    for (int i = 0; i < _activeKeys.length; i++) {
      if (_activeKeys[i] == logicalKey) {
        return true;
      }
    }
    return false;
  }

  /// Explicitly set an action state, e.g. for Virtual Joypad vector X/Y mapping
  void setActionState(int actionId, double value) {
    if (actionId >= 0 && actionId < GameAction.maxActions) {
      _actionStates[actionId] = value;
    }
  }

  double getActionValue(int actionId) {
    if (actionId >= 0 && actionId < GameAction.maxActions) {
      return _actionStates[actionId];
    }
    return 0.0;
  }

  bool isActionActive(int actionId) {
    return getActionValue(actionId) > 0.0;
  }

  InputSource get activeSource => _activeSource;

  void dispose() {
    if (_originalKeyHandler != null) {
      PlatformDispatcher.instance.onKeyData = _originalKeyHandler;
    } else {
      PlatformDispatcher.instance.onKeyData = null;
    }

    if (_originalPointerHandler != null) {
      PlatformDispatcher.instance.onPointerDataPacket = _originalPointerHandler;
    } else {
      PlatformDispatcher.instance.onPointerDataPacket = null;
    }
  }
}
