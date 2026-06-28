import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/swarm.dart';

/// Manages entities and acts as a central registry for all [ComponentCaste]s.
///
/// Wraps the [Swarm] entity manager to provide unified entity lifecycle management
/// (creating and destroying entities). When an entity is destroyed, [Scene] ensures
/// it is cleanly removed from all registered castes.
class Scene {
  final Swarm _swarm;

  /// Registry of all castes tracked by the scene, stored via their type-erased interface.
  final List<AbstractCaste> _castes = [];

  /// Fast lookup map for retrieving castes by their name.
  /// Note: Dart 3 extension types are erased at runtime to their base types,
  /// so we use a string name instead of `Type` to uniquely identify castes.
  final Map<String, AbstractCaste> _casteMap = {};

  /// Creates a new [Scene], optionally accepting an existing [Swarm].
  /// If no [Swarm] is provided, a new one is created.
  Scene({Swarm? swarm}) : _swarm = swarm ?? Swarm();

  /// Registers a [ComponentCaste] with the scene using a unique [name].
  ///
  /// The [caste] will now be automatically updated when entities are destroyed.
  void registerCaste<T>(String name, ComponentCaste<T> caste) {
    if (_casteMap.containsKey(name)) {
      throw StateError('Caste with name "$name" is already registered in the Scene.');
    }
    _castes.add(caste);
    _casteMap[name] = caste;
  }

  /// Retrieves a registered [ComponentCaste] for the given [name].
  ///
  /// Throws a [StateError] if no such caste is registered.
  ComponentCaste<T> getCaste<T>(String name) {
    final caste = _casteMap[name];
    if (caste == null) {
      throw StateError('No Caste registered with name "$name".');
    }
    return caste as ComponentCaste<T>;
  }

  /// Creates a new entity.
  ///
  /// Returns the ID of the new entity, or -1 if the entity limit is reached.
  int createEntity() {
    return _swarm.createEntity();
  }

  /// Destroys the specified entity and removes all its components from registered castes.
  ///
  /// Returns `true` if the entity was successfully destroyed, or `false` if the entity ID was invalid.
  bool destroyEntity(int entity) {
    // Attempt to destroy the entity via Swarm.
    // If it fails (invalid ID or already destroyed), we abort early.
    if (!_swarm.destroyEntity(entity)) {
      return false;
    }

    // Cleanly remove the entity from all registered castes.
    for (var i = 0; i < _castes.length; i++) {
      _castes[i].remove(entity);
    }

    return true;
  }
}
