import '../components/animation_event_trigger.dart';
import '../components/sprite_animation.dart';
import '../ecs/component_storage.dart';
import '../ecs/query.dart';

/// A system that monitors [SpriteAnimation]s and triggers [AnimationEventTrigger]s
/// when the animation reaches a specific frame.
class AnimatedSpriteEventSystem {
  final Query2<SpriteAnimation, AnimationEventTrigger> _query;

  /// Optional zero-allocation callback to handle triggered events directly.
  /// If provided, this will be called when an event is triggered.
  final void Function(int entity, int eventId)? onEventTriggered;

  /// Creates a new [AnimatedSpriteEventSystem].
  AnimatedSpriteEventSystem({
    required ComponentStorage<SpriteAnimation> spriteAnimationCaste,
    required ComponentStorage<AnimationEventTrigger> animationEventTriggerCaste,
    this.onEventTriggered,
  }) : _query = Query2<SpriteAnimation, AnimationEventTrigger>(
          spriteAnimationCaste,
          animationEventTriggerCaste,
        );

  /// Updates the system, checking if any animation frames have reached their trigger targets.
  void update() {
    _query.forEach((entity, animation, trigger) {
      final currentFrame = animation.currentFrameIndex;
      final targetFrame = trigger.targetFrame;

      if (currentFrame == targetFrame) {
        if (!trigger.hasTriggered) {
          trigger.hasTriggered = true;
          if (onEventTriggered != null) {
            onEventTriggered!(entity, trigger.eventId);
          }
        }
      } else {
        // We've moved away from the target frame.
        if (trigger.hasTriggered && !trigger.triggerOnce) {
          // Reset so it can trigger again on the next loop.
          trigger.hasTriggered = false;
        }
      }
    });
  }
}

