import 'package:sting/engine/ecs/sparse_set.dart';

/// Interface for type-erased operations on ComponentStorage.
abstract class AbstractComponentStorage {
  /// Removes the component for the specified entity.
  bool remove(int entity);

  /// Clears the component storage.
  void clear();
}

/// A wrapper around [SparseSet] that stores component data of type [T].
///
/// Ensures component data remains densely packed in memory alongside the entity IDs.
/// Uses a `List<T?>` internally where `T` is the component type.
class ComponentStorage<T> implements AbstractComponentStorage {
  /// The underlying sparse set that tracks entity IDs and dense indices.
  final SparseSet _sparseSet;

  /// The dense array of component data.
  /// Elements match the entity IDs in `_sparseSet.elementAt(index)`.
  final List<T?> _components;

  /// Creates a new `ComponentStorage` with the given capacity.
  ///
  /// [capacity] must match the capacity of the underlying [SparseSet].
  ComponentStorage(int capacity)
      : _sparseSet = SparseSet(capacity),
        _components = List<T?>.filled(capacity, null);

  /// The number of components currently stored.
  int get length => _sparseSet.length;

  /// Adds a component to the specified entity.
  ///
  /// If the entity already has a component in this set, it is overwritten.
  void add(int entity, T component) {
    if (!_sparseSet.contains(entity)) {
      _sparseSet.add(entity);
    }
    final index = _sparseSet.indexOf(entity);
    _components[index] = component;
  }

  /// Gets the component associated with the entity, or `null` if not found.
  T? get(int entity) {
    final index = _sparseSet.indexOf(entity);
    if (index == -1) {
      return null;
    }
    return _components[index];
  }

  /// Removes the component for the specified entity.
  ///
  /// Returns `true` if removed, `false` if the entity was not in the set.
  @override
  bool remove(int entity) {
    final indexToRemove = _sparseSet.indexOf(entity);
    if (indexToRemove == -1) {
      return false;
    }

    final lastIndex = _sparseSet.length - 1;
    final lastComponent = _components[lastIndex];

    _components[indexToRemove] = lastComponent;
    _components[lastIndex] = null;

    _sparseSet.remove(entity);
    return true;
  }

  /// Checks if an entity has a component in this storage.
  bool has(int entity) {
    return _sparseSet.contains(entity);
  }

  /// Clears all components from storage in O(1) structural time.
  @override
  void clear() {
    _sparseSet.clear();
    _components.fillRange(0, _components.length, null);
  }

  /// Gets the entity ID at the specified dense index.
  int elementAt(int index) => _sparseSet.elementAt(index);

  /// Gets the component at the specified dense index.
  T? getComponentAt(int index) {
    if (index < 0 || index >= _sparseSet.length) {
      throw RangeError.index(
          index, this, 'index', 'Index out of range', _sparseSet.length);
    }
    return _components[index];
  }

  /// Gets the entity ID at the specified dense index.
  int entityAt(int index) => elementAt(index);

  /// Gets the component at the specified dense index directly.
  T getAt(int index) => getComponentAt(index) as T;

  /// Direct access to the internal component list for high-performance iteration.
  List<T?> get components => _components;

  /// Direct access to the underlying sparse set.
  SparseSet get sparseSet => _sparseSet;
}

/// Backward-compatible alias for [ComponentStorage].
typedef ComponentCaste<T> = ComponentStorage<T>;

/// Backward-compatible alias for [AbstractComponentStorage].
typedef AbstractCaste = AbstractComponentStorage;
