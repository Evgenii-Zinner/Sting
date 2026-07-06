import '../components/sprite.dart';
import '../components/sprite_animation.dart';
import '../ecs/component_caste.dart';
import '../ecs/query.dart';

class AnimationSystem {
  final Query2<Sprite, SpriteAnimation> query;

  AnimationSystem({
    required ComponentCaste<Sprite> spriteCaste,
    required ComponentCaste<SpriteAnimation> spriteAnimationCaste,
  }) : query =
            Query2<Sprite, SpriteAnimation>(spriteCaste, spriteAnimationCaste);

  void update(double dt) {
    query.forEach((entity, sprite, animation) {
      if (animation.frameCount <= 1) return;

      double elapsed = animation.elapsedTime + dt;
      final duration = animation.frameDuration;

      if (elapsed >= duration) {
        // Calculate how many frames to advance
        int framesToAdvance = (elapsed / duration).floor();
        elapsed -= framesToAdvance * duration;

        int newFrame = (animation.currentFrameIndex + framesToAdvance) %
            animation.frameCount;

        animation.currentFrameIndex = newFrame;

        // Update the Sprite's source rect
        double newLeft = animation.startX + (newFrame * animation.frameWidth);
        double newTop = animation.startY;

        sprite.rectLeft = newLeft;
        sprite.rectTop = newTop;
        sprite.rectRight = newLeft + animation.frameWidth;
        sprite.rectBottom = newTop + animation.frameHeight;
      }

      animation.elapsedTime = elapsed;
    });
  }
}
