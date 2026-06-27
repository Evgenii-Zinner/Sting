import 'dart:typed_data';

/// Manages entity IDs for the Sting engine.
///
/// Ensures zero allocations per frame by pre-allocating fixed-size data structures.
/// Uses a 16-bit unsigned integer limit (65,535 maximum active entities).
class Swarm {
  /// Maximum number of entities allowed.
  static const int maxEntities = 65535;

  /// The next sequential ID to assign if the recycled stack is empty.
  int _nextId = 0;

  /// A stack of recycled IDs.
  final Int32List _recycledIds = Int32List(maxEntities);

  /// The number of recycled IDs currently in the stack.
  int _recycledCount = 0;

  /// Bit array tracking whether an entity ID is currently active.
  /// 65536 bits requires 65536 / 32 = 2048 integers in a Uint32List.
  final Uint32List _activeFlags = Uint32List((maxEntities + 1) ~/ 32 + 1);

  /// Creates a new entity and returns its ID.
  /// Returns -1 if the maximum number of entities (65,535) has been reached.
  int createEntity() {
    int id;

    if (_recycledCount > 0) {
      _recycledCount--;
      id = _recycledIds[_recycledCount];
    } else {
      if (_nextId >= maxEntities) {
        return -1;
      }
      id = _nextId;
      _nextId++;
    }

    // Set the bit indicating this entity is active
    final int intIndex = id ~/ 32;
    final int bitIndex = id % 32;
    _activeFlags[intIndex] |= (1 << bitIndex);

    return id;
  }

  /// Destroys an entity, recycling its ID for future use.
  ///
  /// Returns true if the entity was successfully destroyed.
  /// Returns false if the entity ID is invalid, out of bounds, or already destroyed.
  bool destroyEntity(int id) {
    if (id < 0 || id >= maxEntities) {
      return false;
    }

    final int intIndex = id ~/ 32;
    final int bitIndex = id % 32;

    // Check if the entity is active
    if ((_activeFlags[intIndex] & (1 << bitIndex)) == 0) {
      return false; // Already destroyed or never created
    }

    // Clear the active bit
    _activeFlags[intIndex] &= ~(1 << bitIndex);

    // Push the ID to the recycled stack
    _recycledIds[_recycledCount] = id;
    _recycledCount++;

    return true;
  }
}
