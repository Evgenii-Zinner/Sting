import 'package:sting/engine/components/tween.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/math/easing.dart';

/// A system that updates Tween components by delta time.
/// Uses zero heap allocations per frame.
class TweenSystem {
  final Query1<Tween> query;

  /// Creates a TweenSystem querying entities with a Tween component.
  TweenSystem({
    required ComponentCaste<Tween> tweenCaste,
  }) : query = Query1<Tween>(tweenCaste);

  /// Updates all active Tweens.
  /// Modifies the ByteData directly without allocating new objects.
  void update(double dt) {
    query.forEach((entity, tween) {
      if (tween.isComplete) return;

      double elapsed = tween.elapsed + dt;
      final double duration = tween.duration;

      if (elapsed >= duration) {
        final int loopMode = tween.loopMode;
        if (loopMode == TweenLoopMode.once) {
          elapsed = duration;
          tween.isComplete = true;
        } else if (loopMode == TweenLoopMode.pingPong) {
          // Swap start and end values
          final double temp = tween.startVal;
          tween.startVal = tween.endVal;
          tween.endVal = temp;
          elapsed = elapsed % duration;
        } else if (loopMode == TweenLoopMode.repeat) {
          elapsed = elapsed % duration;
        }
      }

      tween.elapsed = elapsed;

      // Calculate normalized progress (0.0 to 1.0)
      // Guard against division by zero if duration is 0
      double t = duration > 0.0 ? elapsed / duration : 1.0;
      if (t > 1.0) t = 1.0;

      final double easedT = _applyEasing(t, tween.easingType);

      final double startVal = tween.startVal;
      final double endVal = tween.endVal;

      tween.currentVal = startVal + (endVal - startVal) * easedT;
    });
  }

  double _applyEasing(double t, int easingType) {
    if (easingType == TweenEasingType.linear) {
      return Easing.linear(t);
    } else if (easingType == TweenEasingType.easeInQuad) {
      return Easing.easeInQuad(t);
    } else if (easingType == TweenEasingType.easeOutQuad) {
      return Easing.easeOutQuad(t);
    } else if (easingType == TweenEasingType.easeInOutQuad) {
      return Easing.easeInOutQuad(t);
    } else if (easingType == TweenEasingType.easeInCubic) {
      return Easing.easeInCubic(t);
    } else if (easingType == TweenEasingType.easeOutCubic) {
      return Easing.easeOutCubic(t);
    } else if (easingType == TweenEasingType.easeOutBounce) {
      return Easing.easeOutBounce(t);
    } else if (easingType == TweenEasingType.easeOutElastic) {
      return Easing.easeOutElastic(t);
    }
    return Easing.linear(t); // Default fallback
  }
}
