import 'dart:typed_data';

import 'package:sting/engine/ecs/swarm.dart';

/// An integer-based Sparse Set data structure for mapping entity IDs to contiguous indices.
///
/// Named `Caste` to fit the insect/sting theme (a group of entities).
/// Uses the Briggs & Torczon validation technique to eliminate the need for
/// sentinel values and allows O(1) `clear()` by just resetting the length.
///
/// Limits: Max entity ID is 65535, so this utilizes `Uint16List`.
class Caste {
  /// The sparse array mapping Entity ID -> dense array index.
  /// Fixed size to the global maximum possible entities (65536).
  final Uint16List _sparse;

  /// The dense array mapping dense array index -> Entity ID.
  /// Size is user-configurable up to the maximum limit.
  final Uint16List _dense;

  /// The current number of active elements in the set.
  int _length = 0;

  /// Creates a new Caste (Sparse Set) with the given maximum capacity.
  ///
  /// [capacity] is the maximum number of elements this set can hold,
  /// strictly pre-allocated. Must not exceed [Swarm.maxEntities].
  Caste(int capacity)
      : _sparse = Uint16List(Swarm.maxEntities + 1),
        _dense = Uint16List(capacity) {
    if (capacity < 0 || capacity > Swarm.maxEntities + 1) {
      throw ArgumentError.value(capacity, 'capacity', 'Must be between 0 and ${Swarm.maxEntities + 1}');
    }
  }

  /// The number of elements currently in the set.
  int get length => _length;

  /// Gets the entity ID at the specified dense index.
  ///
  /// Useful for fast O(1) linear iteration.
  int elementAt(int index) {
    if (index < 0 || index >= _length) {
      throw RangeError.index(index, this, 'index', 'Index out of range', _length);
    }
    return _dense[index];
  }

  /// Returns the dense array index of the given entity.
  ///
  /// Returns -1 if the entity is invalid or not in the set.
  int indexOf(int entity) {
    if (entity < 0 || entity > Swarm.maxEntities) {
      return -1; // Out of bounds entities can't be in the set
    }

    // Briggs & Torczon validation
    final index = _sparse[entity];
    if (index < _length && _dense[index] == entity) {
      return index;
    }
    return -1;
  }

  /// Checks if the given entity is present in the set.
  bool contains(int entity) {
    return indexOf(entity) != -1;
  }

  /// Adds an entity to the set.
  ///
  /// Throws [RangeError] if entity is invalid.
  /// Throws [StateError] if the set is at full capacity.
  void add(int entity) {
    if (entity < 0 || entity > Swarm.maxEntities) {
      throw RangeError.value(entity, 'entity', 'Must be between 0 and ${Swarm.maxEntities}');
    }

    if (contains(entity)) {
      return; // Already in the set
    }

    if (_length >= _dense.length) {
      throw StateError('Caste is at full capacity (${_dense.length})');
    }

    _dense[_length] = entity;
    _sparse[entity] = _length;
    _length++;
  }

  /// Removes an entity from the set.
  ///
  /// Returns `true` if the entity was removed, or `false` if it was not in the set.
  bool remove(int entity) {
    if (!contains(entity)) {
      return false;
    }

    // Swap-with-last to keep dense array contiguous
    final indexToRemove = _sparse[entity];
    final lastEntity = _dense[_length - 1];

    // Move the last entity into the hole
    _dense[indexToRemove] = lastEntity;
    _sparse[lastEntity] = indexToRemove;

    _length--;
    return true;
  }

  /// Clears the set in O(1) time.
  void clear() {
    _length = 0;
  }
}
