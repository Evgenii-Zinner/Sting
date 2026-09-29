import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/animation_event_trigger.dart';
import 'package:sting/engine/components/sprite_animation.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/animated_sprite_event_system.dart';

void main() {
  group('AnimatedSpriteEventSystem', () {
    late ComponentStorage<SpriteAnimation> spriteAnimationCaste;
    late ComponentStorage<AnimationEventTrigger> triggerCaste;
    late AnimatedSpriteEventSystem system;

    late int triggeredEntity;
    late int triggeredEventId;
    late int triggerCount;

    setUp(() {
      spriteAnimationCaste = ComponentStorage<SpriteAnimation>(10);
      triggerCaste = ComponentStorage<AnimationEventTrigger>(10);

      triggeredEntity = -1;
      triggeredEventId = -1;
      triggerCount = 0;

      system = AnimatedSpriteEventSystem(
        spriteAnimationCaste: spriteAnimationCaste,
        animationEventTriggerCaste: triggerCaste,
        onEventTriggered: (entity, eventId) {
          triggeredEntity = entity;
          triggeredEventId = eventId;
          triggerCount++;
        },
      );
    });

    test('Trigger fires exactly once when the target frame is reached', () {
      final animation = SpriteAnimation.create(0.1, 5);
      final trigger = AnimationEventTrigger.create(2, 42);

      spriteAnimationCaste.add(1, animation);
      triggerCaste.add(1, trigger);

      // Frame 0: shouldn't trigger
      animation.currentFrameIndex = 0;
      system.update();
      expect(triggerCount, 0);

      // Frame 1: shouldn't trigger
      animation.currentFrameIndex = 1;
      system.update();
      expect(triggerCount, 0);

      // Frame 2: should trigger
      animation.currentFrameIndex = 2;
      system.update();
      expect(triggerCount, 1);
      expect(triggeredEntity, 1);
      expect(triggeredEventId, 42);
      expect(trigger.hasTriggered, true);
    });

    test('Trigger does not fire again while remaining on the target frame', () {
      final animation = SpriteAnimation.create(0.1, 5);
      final trigger = AnimationEventTrigger.create(2, 42);

      spriteAnimationCaste.add(1, animation);
      triggerCaste.add(1, trigger);

      // Reach frame 2
      animation.currentFrameIndex = 2;
      system.update();
      expect(triggerCount, 1);

      // Update again while still on frame 2
      system.update();
      expect(triggerCount, 1); // Should not increase
    });

    test(
        'Trigger resets and fires again on next loop if triggerOnce is false',
        () {
      final animation = SpriteAnimation.create(0.1, 5);
      final trigger = AnimationEventTrigger.create(2, 42, triggerOnce: false);

      spriteAnimationCaste.add(1, animation);
      triggerCaste.add(1, trigger);

      // Loop 1: Reach frame 2
      animation.currentFrameIndex = 2;
      system.update();
      expect(triggerCount, 1);

      // Move past frame 2 (trigger should reset)
      animation.currentFrameIndex = 3;
      system.update();
      expect(triggerCount, 1);
      expect(trigger.hasTriggered, false);

      // Loop 2: Reach frame 2 again
      animation.currentFrameIndex = 2;
      system.update();
      expect(triggerCount, 2);
    });

    test('Trigger does not fire again on subsequent loops if triggerOnce is true', () {
      final animation = SpriteAnimation.create(0.1, 5);
      final trigger = AnimationEventTrigger.create(2, 42, triggerOnce: true);

      spriteAnimationCaste.add(1, animation);
      triggerCaste.add(1, trigger);

      // Loop 1: Reach frame 2
      animation.currentFrameIndex = 2;
      system.update();
      expect(triggerCount, 1);

      // Move past frame 2 (trigger should NOT reset)
      animation.currentFrameIndex = 3;
      system.update();
      expect(triggerCount, 1);
      expect(trigger.hasTriggered, true);

      // Loop 2: Reach frame 2 again
      animation.currentFrameIndex = 2;
      system.update();
      expect(triggerCount, 1); // Should not increase
    });
  });
}
