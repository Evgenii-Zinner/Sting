import 'package:sting/engine/ecs/scene.dart';

/// A callback used to initialize components on a newly spawned entity.
typedef PrefabInitializer = void Function(Scene scene, int entity);

/// Defines an archetype that can spawn pre-configured entities.
class Prefab {
  /// The initializer callback that attaches and configures components.
  final PrefabInitializer initializer;

  /// Creates a [Prefab] with the given [initializer].
  const Prefab(this.initializer);

  /// Spawns a new entity in the [scene] and applies the [initializer].
  ///
  /// Returns the ID of the newly created entity, or -1 if the entity limit was reached.
  int spawn(Scene scene) {
    final entity = scene.createEntity();
    if (entity != -1) {
      initializer(scene, entity);
    }
    return entity;
  }
}
