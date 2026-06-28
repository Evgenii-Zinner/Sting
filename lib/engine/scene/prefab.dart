import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/scene.dart';

/// A utility class containing static factory methods for spawning common entity types.
///
/// Designed to streamline scene assembly while adhering to strict ECS rules
/// and zero-allocation per frame constraints. It only relies on primitive parameters.
class Prefab {
  /// Spawns a standard enemy entity with [Position], [Velocity], [BoundingBox], and [Sprite] components.
  ///
  /// The [scene] must have the respective `ComponentCaste`s registered.
  /// Returns the spawned entity ID, or -1 if the entity limit is reached.
  static int spawnStandardEnemy(
    Scene scene,
    double x,
    double y,
    double vx,
    double vy,
    double width,
    double height,
  ) {
    // Attempt to create the entity first
    final entity = scene.createEntity();
    if (entity == -1) {
      return -1;
    }

    // Retrieve required castes (throws StateError if not registered)
    final positionCaste = scene.getCaste<Position>('Position');
    final velocityCaste = scene.getCaste<Velocity>('Velocity');
    final boundingBoxCaste = scene.getCaste<BoundingBox>('BoundingBox');
    final spriteCaste = scene.getCaste<Sprite>('Sprite');

    // Instantiate and add components
    positionCaste.add(entity, Position.create(x, y));
    velocityCaste.add(entity, Velocity.create(vx, vy));
    boundingBoxCaste.add(entity, BoundingBox.create(width, height));
    spriteCaste.add(entity, Sprite.create());

    return entity;
  }
}
