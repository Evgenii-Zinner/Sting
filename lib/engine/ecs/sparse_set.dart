import 'dart:typed_data';

import 'package:sting/engine/ecs/entity_manager.dart';

/// An integer-based Sparse Set data structure for mapping entity IDs to contiguous indices.
///
/// Uses the Briggs & Torczon validation technique to eliminate the need for
/// sentinel values and allows O(1) `clear()` by just resetting the length.
///
/// Limits: Max entity ID is 65535, so this utilizes `Uint16List`.
class SparseSet {
  /// The sparse array mapping Entity ID -> dense array index.
  /// Fixed size to the global maximum possible entities (65536).
  final Uint16List _sparse;

  /// The dense array mapping dense array index -> Entity ID.
  /// Size is user-configurable up to the maximum limit.
  final Uint16List _dense;

  /// The current number of active elements in the set.
  int _length = 0;

  /// Creates a new SparseSet with the given maximum capacity.
  ///
  /// [capacity] is the maximum number of elements this set can hold,
  /// strictly pre-allocated. Must not exceed [EntityManager.maxEntities].
  SparseSet(int capacity)
      : _sparse = Uint16List(EntityManager.maxEntities + 1),
        _dense = Uint16List(capacity) {
    if (capacity < 0 || capacity > EntityManager.maxEntities + 1) {
      throw ArgumentError.value(capacity, 'capacity',
          'Must be between 0 and ${EntityManager.maxEntities + 1}');
    }
  }

  /// The number of elements currently in the set.
  int get length => _length;

  /// Gets the entity ID at the specified dense index.
  ///
  /// Useful for fast O(1) linear iteration.
  int elementAt(int index) {
    if (index < 0 || index >= _length) {
      throw RangeError.index(
          index, this, 'index', 'Index out of range', _length);
    }
    return _dense[index];
  }

  /// Checks if the set contains the specified entity ID.
  ///
  /// Uses Briggs & Torczon validation:
  /// 1. Look up the candidate dense index in `_sparse[entity]`.
  /// 2. Verify that index is within the active dense bounds (`0 <= index < _length`).
  /// 3. Verify that `_dense[index] == entity` (the reciprocal link).
  bool contains(int entity) {
    if (entity < 0 || entity >= _sparse.length) {
      return false;
    }
    final int index = _sparse[entity];
    return index < _length && _dense[index] == entity;
  }

  /// Adds an entity ID to the set.
  ///
  /// Returns `true` if the entity was added, or `false` if it was already present.
  /// Throws [StateError] if the set is at full capacity.
  bool add(int entity) {
    if (entity < 0 || entity >= _sparse.length) {
      throw RangeError.range(
          entity, 0, _sparse.length - 1, 'entity', 'Entity ID out of bounds');
    }

    if (contains(entity)) {
      return false;
    }

    if (_length >= _dense.length) {
      throw StateError('SparseSet is full (capacity: ${_dense.length})');
    }

    _dense[_length] = entity;
    _sparse[entity] = _length;
    _length++;
    return true;
  }

  /// Removes an entity ID from the set using swap-and-pop.
  ///
  /// Returns `true` if the entity was removed, or `false` if it was not in the set.
  bool remove(int entity) {
    if (!contains(entity)) {
      return false;
    }

    final int indexToRemove = _sparse[entity];
    final int lastEntity = _dense[_length - 1];

    // Move the last element into the removed element's slot
    _dense[indexToRemove] = lastEntity;
    _sparse[lastEntity] = indexToRemove;

    _length--;
    return true;
  }

  /// Gets the dense index for an entity, or -1 if the entity is not in the set.
  int indexOf(int entity) {
    if (contains(entity)) {
      return _sparse[entity];
    }
    return -1;
  }

  /// Clears the set in O(1) time.
  ///
  /// Due to Briggs & Torczon validation, we only need to reset `_length` to 0.
  void clear() {
    _length = 0;
  }

  /// Exposes the underlying dense list for zero-allocation iteration.
  Uint16List get dense => _dense;
}
