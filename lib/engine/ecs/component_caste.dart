import 'package:sting/engine/ecs/caste.dart';

/// Interface for type-erased operations on Castes.
abstract class AbstractCaste {
  /// Removes the component for the specified entity.
  bool remove(int entity);

  /// Clears the component storage.
  void clear();
}

/// A wrapper around [Caste] that stores component data of type [T].
///
/// Ensures component data remains densely packed in memory alongside the entity IDs.
/// Uses a `List<T?>` internally where `T` is the component type.
class ComponentCaste<T> implements AbstractCaste {
  /// The underlying sparse set that tracks entity IDs and dense indices.
  final Caste _caste;

  /// The dense array of component data.
  /// Elements match the entity IDs in `_caste.elementAt(index)`.
  final List<T?> _components;

  /// Creates a new `ComponentCaste` with the given capacity.
  ///
  /// [capacity] must match the capacity of the underlying [Caste].
  ComponentCaste(int capacity)
      : _caste = Caste(capacity),
        _components = List<T?>.filled(capacity, null);

  /// The number of components currently stored.
  int get length => _caste.length;

  /// Adds a component to the specified entity.
  ///
  /// If the entity already has a component in this set, it is overwritten.
  void add(int entity, T component) {
    if (!_caste.contains(entity)) {
      _caste.add(entity);
    }
    final index = _caste.indexOf(entity);
    _components[index] = component;
  }

  /// Gets the component associated with the entity, or `null` if not found.
  T? get(int entity) {
    final index = _caste.indexOf(entity);
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
    final indexToRemove = _caste.indexOf(entity);
    if (indexToRemove == -1) {
      return false;
    }

    final lastIndex = _caste.length - 1;

    // Swap the component at indexToRemove with the last component,
    // to match the swap happening inside Caste.remove().
    if (indexToRemove != lastIndex) {
      _components[indexToRemove] = _components[lastIndex];
    }

    // Nullify the last component (now effectively removed or swapped)
    _components[lastIndex] = null;

    _caste.remove(entity);
    return true;
  }

  /// Gets the component at the specific dense array index.
  ///
  /// Throws [RangeError] if index is out of bounds.
  T? getComponentAt(int index) {
    if (index < 0 || index >= _caste.length) {
      throw RangeError.index(
          index, this, 'index', 'Index out of range', _caste.length);
    }
    return _components[index];
  }

  /// Gets the entity ID at the specific dense array index.
  int elementAt(int index) {
    return _caste.elementAt(index);
  }

  /// Clears the component storage in O(1) time.
  @override
  void clear() {
    _caste.clear();
    // We don't need to actually clear `_components` array since `get()`
    // and `getComponentAt()` rely on `_caste.length` and `_caste.indexOf()`.
    // However, to prevent memory leaks for object components, we might want to nullify.
    // For Phase 1, flat data structures will be used, but nullifying is safer for GC.
    // However, the rule is to avoid O(N) operations on clear if possible.
    // Given the constraints, O(1) clear is preferred. We will just let them be overwritten later.
  }
}
