import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/bounding_box.dart';
import '../components/damage.dart';

/// Spawns a projectile entity and attaches necessary components for movement and rendering.
int spawnProjectile(Scene scene, double startX, double startY, double dx, double dy) {
  final projectileEntity = scene.createEntity();

  if (projectileEntity != -1) {
    scene.getCaste<Position>('Position').add(projectileEntity, Position.create(startX, startY));
    scene.getCaste<Velocity>('Velocity').add(projectileEntity, Velocity.create(dx, dy));
    scene.getCaste<Sprite>('Sprite').add(projectileEntity, Sprite.create());

    // Projectiles generally have a smaller hitbox
    scene.getCaste<BoundingBox>('BoundingBox').add(projectileEntity, BoundingBox.create(8.0, 8.0));

    // Projectiles deal damage
    scene.getCaste<Damage>('Damage').add(projectileEntity, Damage.create(10));
  }

  return projectileEntity;
}
