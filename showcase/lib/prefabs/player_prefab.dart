import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/sprite_animation.dart';
import 'package:sting/engine/components/bounding_box.dart';
import '../components/weapon.dart';

/// Spawns a player entity and attaches necessary components for movement and rendering.
int spawnPlayer(Scene scene, double startX, double startY) {
  final playerEntity = scene.createEntity();

  if (playerEntity != -1) {
    scene.getCaste<Position>('Position').add(playerEntity, Position.create(startX, startY));
    scene.getCaste<Velocity>('Velocity').add(playerEntity, Velocity.create(0.0, 0.0));
    scene.getCaste<Sprite>('Sprite').add(playerEntity, Sprite.create());

    // Placeholder animation: 4 frames, 0.1s duration, frame size 32x32.
    scene.getCaste<SpriteAnimation>('SpriteAnimation').add(
      playerEntity,
      SpriteAnimation.create(0.1, 4, frameWidth: 32.0, frameHeight: 32.0)
    );

    // Hitbox smaller than visual size for better gameplay feel
    scene.getCaste<BoundingBox>('BoundingBox').add(playerEntity, BoundingBox.create(16.0, 24.0));

    // Add weapon component (fireRate, projectileSpeed, range)
    scene.getCaste<Weapon>('Weapon').add(playerEntity, Weapon.create(0.5, 300.0, 200.0));
  }

  return playerEntity;
}
