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

    test('Advances frame when duration is met', () {
      spriteCaste.add(1, Sprite.create());
      final anim = SpriteAnimation.create(0.1, 4);
      animationCaste.add(1, anim);

      system.update(0.12);

      final updatedAnim = animationCaste.get(1)!;
      expect(updatedAnim.currentFrameIndex, 1);
      expect(updatedAnim.elapsedTime, closeTo(0.02, 0.0001));
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
      spriteCaste.add(1, Sprite.create());
      final anim = SpriteAnimation.create(0.1, 4);
      anim.currentFrameIndex = 3;
      animationCaste.add(1, anim);

      system.update(0.15);

      final updatedAnim = animationCaste.get(1)!;
      expect(updatedAnim.currentFrameIndex, 0);
      expect(updatedAnim.elapsedTime, closeTo(0.05, 0.0001));
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
