import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/sprite_animation.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/animation_system.dart';

void main() {
  group('AnimationSystem', () {
    late ComponentCaste<Sprite> spriteCaste;
    late ComponentCaste<SpriteAnimation> animationCaste;
    late AnimationSystem system;

    setUp(() {
      spriteCaste = ComponentCaste<Sprite>(10);
      animationCaste = ComponentCaste<SpriteAnimation>(10);

      system = AnimationSystem(
        spriteCaste: spriteCaste,
        spriteAnimationCaste: animationCaste,
      );
    });

    test('Does not update frame before duration is met', () {
      spriteCaste.add(1, Sprite.create());
      final anim = SpriteAnimation.create(0.1, 4);
      animationCaste.add(1, anim);

      system.update(0.05);

      final updatedAnim = animationCaste.get(1)!;
      expect(updatedAnim.currentFrameIndex, 0);
      expect(updatedAnim.elapsedTime, closeTo(0.05, 0.0001));
    });

    test('Advances frame when duration is met and updates sprite rect', () {
      final sprite = Sprite.create();
      spriteCaste.add(1, sprite);
      final anim = SpriteAnimation.create(
        0.1,
        4,
        frameWidth: 32.0,
        frameHeight: 32.0,
        startX: 10.0,
        startY: 10.0,
      );
      animationCaste.add(1, anim);

      system.update(0.12);

      final updatedAnim = animationCaste.get(1)!;
      expect(updatedAnim.currentFrameIndex, 1);
      expect(updatedAnim.elapsedTime, closeTo(0.02, 0.0001));

      final updatedSprite = spriteCaste.get(1)!;
      // newFrame = 1
      // left = 10.0 + (1 * 32.0) = 42.0
      // top = 10.0
      // right = 42.0 + 32.0 = 74.0
      // bottom = 10.0 + 32.0 = 42.0
      expect(updatedSprite.rectLeft, closeTo(42.0, 0.0001));
      expect(updatedSprite.rectTop, closeTo(10.0, 0.0001));
      expect(updatedSprite.rectRight, closeTo(74.0, 0.0001));
      expect(updatedSprite.rectBottom, closeTo(42.0, 0.0001));
    });

    test('Advances multiple frames if dt is large', () {
      spriteCaste.add(1, Sprite.create());
      final anim = SpriteAnimation.create(0.1, 4);
      animationCaste.add(1, anim);

      system.update(0.25);

      final updatedAnim = animationCaste.get(1)!;
      expect(updatedAnim.currentFrameIndex, 2);
      expect(updatedAnim.elapsedTime, closeTo(0.05, 0.0001));
    });

    test('Loops back to frame 0 after reaching frameCount', () {
      final sprite = Sprite.create();
      spriteCaste.add(1, sprite);
      final anim = SpriteAnimation.create(
        0.1,
        4,
        frameWidth: 16.0,
        frameHeight: 16.0,
        startX: 0.0,
        startY: 0.0,
      );
      anim.currentFrameIndex = 3;
      animationCaste.add(1, anim);

      system.update(0.15);

      final updatedAnim = animationCaste.get(1)!;
      expect(updatedAnim.currentFrameIndex, 0);
      expect(updatedAnim.elapsedTime, closeTo(0.05, 0.0001));

      final updatedSprite = spriteCaste.get(1)!;
      // newFrame = 0
      // left = 0.0 + (0 * 16.0) = 0.0
      // top = 0.0
      // right = 0.0 + 16.0 = 16.0
      // bottom = 0.0 + 16.0 = 16.0
      expect(updatedSprite.rectLeft, closeTo(0.0, 0.0001));
      expect(updatedSprite.rectTop, closeTo(0.0, 0.0001));
      expect(updatedSprite.rectRight, closeTo(16.0, 0.0001));
      expect(updatedSprite.rectBottom, closeTo(16.0, 0.0001));
    });

    test('Does not update if frameCount is 1', () {
      spriteCaste.add(1, Sprite.create());
      final anim = SpriteAnimation.create(0.1, 1);
      animationCaste.add(1, anim);

      system.update(0.5);

      final updatedAnim = animationCaste.get(1)!;
      expect(updatedAnim.currentFrameIndex, 0);
      expect(updatedAnim.elapsedTime, 0.0);
    });
  });
}
