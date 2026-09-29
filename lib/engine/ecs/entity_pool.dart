import 'dart:typed_data';

import 'package:sting/engine/ecs/prefab.dart';
import 'package:sting/engine/ecs/scene.dart';

/// Maintains a free list of reusable entity IDs for specific archetypes.
///
/// Designed to spawn and despawn entities without triggering GC pressure
/// or re-allocation. Uses an internal [Int32List] to store the free IDs.
class EntityPool {
  /// The scene that entities are spawned in.
  final Scene scene;

  /// The prefab defining the archetype to spawn.
  final Prefab prefab;

  /// The maximum number of free entities this pool can store.
  final int capacity;

  /// The array used as a stack to hold the recycled entity IDs.
  final Int32List _freeList;

  /// The current number of entities in the free list.
  int _freeCount = 0;

  /// Creates a new [EntityPool] for the given [scene] and [prefab],
  /// with a pre-allocated [capacity] for the free list.
  EntityPool({
    required this.scene,
    required this.prefab,
    required this.capacity,
  }) : _freeList = Int32List(capacity);

  /// Spawns an entity.
  ///
  /// If the free list is not empty, pops and returns an entity from it.
  /// Otherwise, uses the [prefab] to spawn a new entity in the [scene].
  int spawn() {
    if (_freeCount > 0) {
      _freeCount--;
      return _freeList[_freeCount];
    }
    return prefab.spawn(scene);
  }

  /// Despawns the given [entity] by pushing it onto the free list.
  ///
  /// Returns `true` if the entity was successfully added to the free list.
  /// Returns `false` if the pool is full and cannot accept more entities.
  bool despawn(int entity) {
    if (_freeCount >= capacity) {
      return false; // Pool is full
    }
    _freeList[_freeCount] = entity;
    _freeCount++;
    return true;
  }

  /// Pre-spawns [count] entities and places them into the free list.
  ///
  /// The [count] cannot exceed the pool's remaining capacity.
  /// Returns the number of entities successfully populated.
  int populate(int count) {
    int populated = 0;
    while (populated < count && _freeCount < capacity) {
      final entity = prefab.spawn(scene);
      if (entity == -1) {
        break; // Reached global entity limit
      }
      _freeList[_freeCount] = entity;
      _freeCount++;
      populated++;
    }
    return populated;
  }

  /// Gets the current number of entities in the free list.
  int get freeCount => _freeCount;
}
