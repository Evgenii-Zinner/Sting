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

/// A query that iterates over three ComponentCastes, finding the intersection
/// of entities that have components in all three castes.
class Query3<T1, T2, T3> {
  final ComponentCaste<T1> _caste1;
  final ComponentCaste<T2> _caste2;
  final ComponentCaste<T3> _caste3;

  Query3(this._caste1, this._caste2, this._caste3);

  /// Iterates over all entities that exist in all three castes, executing [action].
  /// Uses a callback to avoid allocating Iterator objects during loops.
  void forEach(void Function(int entity, T1 c1, T2 c2, T3 c3) action) {
    // Find the smallest caste for optimal iteration
    int len1 = _caste1.length;
    int len2 = _caste2.length;
    int len3 = _caste3.length;

    if (len1 <= len2 && len1 <= len3) {
      for (var i = 0; i < len1; i++) {
        final entity = _caste1.elementAt(i);
        final c2 = _caste2.get(entity);
        if (c2 != null) {
          final c3 = _caste3.get(entity);
          if (c3 != null) {
            final c1 = _caste1.getComponentAt(i);
            if (c1 != null) {
              action(entity, c1, c2, c3);
            }
          }
        }
      }
    } else if (len2 <= len1 && len2 <= len3) {
      for (var i = 0; i < len2; i++) {
        final entity = _caste2.elementAt(i);
        final c1 = _caste1.get(entity);
        if (c1 != null) {
          final c3 = _caste3.get(entity);
          if (c3 != null) {
            final c2 = _caste2.getComponentAt(i);
            if (c2 != null) {
              action(entity, c1, c2, c3);
            }
          }
        }
      }
    } else {
      for (var i = 0; i < len3; i++) {
        final entity = _caste3.elementAt(i);
        final c1 = _caste1.get(entity);
        if (c1 != null) {
          final c2 = _caste2.get(entity);
          if (c2 != null) {
            final c3 = _caste3.getComponentAt(i);
            if (c3 != null) {
              action(entity, c1, c2, c3);
            }
          }
        }
      }
    }
  }
}
