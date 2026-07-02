import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/sprite_animation.dart';
import 'package:sting/engine/components/bounding_box.dart';
import '../components/weapon.dart';
import '../components/health.dart';
import '../components/exp_magnet.dart';
import '../components/player_stats.dart';

/// Spawns a player entity and attaches necessary components for movement and rendering.
int spawnPlayer(Scene scene, double startX, double startY) {
  final playerEntity = scene.createEntity();

  if (playerEntity != -1) {
    scene.getCaste<Position>('Position').add(playerEntity, Position.create(startX, startY));
    scene.getCaste<Velocity>('Velocity').add(playerEntity, Velocity.create(0.0, 0.0));

    final sprite = Sprite.create();
    // Atlas player frames start at y = 128
    sprite.rectLeft = 0.0;
    sprite.rectTop = 128.0;
    sprite.rectRight = 32.0;
    sprite.rectBottom = 160.0;
    scene.getCaste<Sprite>('Sprite').add(playerEntity, sprite);

    // Placeholder animation: 4 frames, 0.1s duration, frame size 32x32.
    final anim = SpriteAnimation.create(0.1, 4, frameWidth: 32.0, frameHeight: 32.0);
    // Because frames in atlas are laid out horizontally, no need to update rectTop dynamically here,
    // but the system will animate rectLeft and rectRight
    scene.getCaste<SpriteAnimation>('SpriteAnimation').add(playerEntity, anim);

    // Hitbox smaller than visual size for better gameplay feel
    scene.getCaste<BoundingBox>('BoundingBox').add(playerEntity, BoundingBox.create(16.0, 24.0));

    // Add weapon component (fireRate, projectileSpeed, range)
    scene.getCaste<Weapon>('Weapon').add(playerEntity, Weapon.create(0.5, 300.0, 200.0));

    // Gameplay stats and magnet
    scene.getCaste<Health>('Health').add(playerEntity, Health.create(100));
    scene.getCaste<ExpMagnet>('ExpMagnet').add(playerEntity, ExpMagnet.create(100.0));
    scene.getCaste<PlayerStats>('PlayerStats').add(playerEntity, PlayerStats.create());
  }

  return playerEntity;
}
