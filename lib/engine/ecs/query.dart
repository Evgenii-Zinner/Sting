import 'package:sting/engine/ecs/component_caste.dart';

/// A query that iterates over a single ComponentCaste.
class Query1<T> {
  final ComponentCaste<T> _caste;

  Query1(this._caste);

  /// Iterates over all entities in the caste, executing [action] for each.
  /// Uses a callback to avoid allocating Iterator objects during loops.
  void forEach(void Function(int entity, T component) action) {
    final length = _caste.length;
    for (var i = 0; i < length; i++) {
      final entity = _caste.elementAt(i);
      final component = _caste.getComponentAt(i);
      if (component != null) {
        action(entity, component);
      }
    }
  }
}

/// A query that iterates over two ComponentCastes, finding the intersection
/// of entities that have components in both castes.
class Query2<T1, T2> {
  final ComponentCaste<T1> _caste1;
  final ComponentCaste<T2> _caste2;

  Query2(this._caste1, this._caste2);

  /// Iterates over all entities that exist in both castes, executing [action].
  /// Uses a callback to avoid allocating Iterator objects during loops.
  void forEach(void Function(int entity, T1 component1, T2 component2) action) {
    // Iterate over the smaller caste for better performance
    final caste1Smaller = _caste1.length <= _caste2.length;
    final primaryCaste = caste1Smaller ? _caste1 : _caste2;

    final length = primaryCaste.length;

    if (caste1Smaller) {
      for (var i = 0; i < length; i++) {
        final entity = _caste1.elementAt(i);
        final component2 = _caste2.get(entity);
        if (component2 != null) {
           final component1 = _caste1.getComponentAt(i);
           if (component1 != null) {
              action(entity, component1, component2);
           }
        }
      }
    } else {
      for (var i = 0; i < length; i++) {
        final entity = _caste2.elementAt(i);
        final component1 = _caste1.get(entity);
        if (component1 != null) {
           final component2 = _caste2.getComponentAt(i);
           if (component2 != null) {
              action(entity, component1, component2);
           }
        }
      }
    }
  }
}
