import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/entity_manager.dart';

/// Manages entities and acts as a central registry for all [ComponentStorage]s.
///
/// Wraps the [EntityManager] to provide unified entity lifecycle management
/// (creating and destroying entities). When an entity is destroyed, [Scene] ensures
/// it is cleanly removed from all registered storages.
class Scene {
  final EntityManager _entityManager;

  /// Registry of all storages tracked by the scene, stored via their type-erased interface.
  final List<AbstractComponentStorage> _storages = [];

  /// Fast lookup map for retrieving storages by their name.
  final Map<String, AbstractComponentStorage> _storageMap = {};

  /// Creates a new [Scene], optionally accepting an existing [EntityManager].
  Scene({EntityManager? entityManager, EntityManager? swarm})
      : _entityManager = entityManager ?? swarm ?? EntityManager();

  /// The underlying entity manager.
  EntityManager get entityManager => _entityManager;

  /// Alias for entityManager to maintain compatibility.
  EntityManager get swarm => _entityManager;

  /// Registers a [ComponentStorage] with the scene using a unique [name].
  void registerStorage<T>(String name, ComponentStorage<T> storage) {
    if (_storageMap.containsKey(name)) {
      throw StateError(
          'Storage with name "$name" is already registered in the Scene.');
    }
    _storages.add(storage);
    _storageMap[name] = storage;
  }

  /// Backward-compatible alias for [registerStorage].
  void registerCaste<T>(String name, ComponentStorage<T> storage) =>
      registerStorage<T>(name, storage);

  /// Retrieves a registered [ComponentStorage] for the given [name].
  ComponentStorage<T> getStorage<T>(String name) {
    final storage = _storageMap[name];
    if (storage == null) {
      throw StateError('No Storage registered with name "$name".');
    }
    return storage as ComponentStorage<T>;
  }

  /// Backward-compatible alias for [getStorage].
  ComponentStorage<T> getCaste<T>(String name) => getStorage<T>(name);

  /// Creates a new entity.
  int createEntity() {
    return _entityManager.createEntity();
  }

  /// Destroys the specified entity and removes all its components from registered storages.
  bool destroyEntity(int entity) {
    if (!_entityManager.destroyEntity(entity)) {
      return false;
    }

    for (int i = 0; i < _storages.length; i++) {
      _storages[i].remove(entity);
    }

    return true;
  }

  /// Clears all entities and empties all registered storages.
  void clear() {
    _entityManager.reset();
    for (int i = 0; i < _storages.length; i++) {
      _storages[i].clear();
    }
  }

  /// Returns the number of currently active entities.
  int get activeEntityCount => _entityManager.activeEntityCount;
}
