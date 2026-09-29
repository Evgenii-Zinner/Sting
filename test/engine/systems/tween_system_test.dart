import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/tween.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/tween_system.dart';

void main() {
  group('TweenSystem', () {
    late ComponentStorage<Tween> tweenCaste;
    late TweenSystem tweenSystem;

    setUp(() {
      tweenCaste = ComponentStorage<Tween>(10);
      tweenSystem = TweenSystem(tweenCaste: tweenCaste);
    });

    test('updates linear tween currentVal and elapsed', () {
      final tween = Tween.create(
        targetProperty: 0,
        startVal: 10.0,
        endVal: 20.0,
        duration: 2.0,
        easingType: TweenEasingType.linear,
        loopMode: TweenLoopMode.once,
      );
      tweenCaste.add(1, tween);

      tweenSystem.update(1.0); // Halfway
      final updatedTween = tweenCaste.get(1)!;

      expect(updatedTween.elapsed, 1.0);
      expect(updatedTween.currentVal, 15.0);
      expect(updatedTween.isComplete, isFalse);

      tweenSystem.update(1.0); // Finish

      expect(updatedTween.elapsed, 2.0);
      expect(updatedTween.currentVal, 20.0);
      expect(updatedTween.isComplete, isTrue);

      tweenSystem.update(1.0); // Overtime
      // Should not update past duration because isComplete is true
      expect(updatedTween.elapsed, 2.0);
      expect(updatedTween.currentVal, 20.0);
    });

    test('pingPong loop mode reverses values', () {
      final tween = Tween.create(
        targetProperty: 0,
        startVal: 0.0,
        endVal: 10.0,
        duration: 1.0,
        easingType: TweenEasingType.linear,
        loopMode: TweenLoopMode.pingPong,
      );
      tweenCaste.add(1, tween);

      tweenSystem.update(1.0); // Reach end of first ping
      final updatedTween = tweenCaste.get(1)!;

      // Swap should have occurred for the next frame, elapsed reset
      expect(updatedTween.startVal, 10.0);
      expect(updatedTween.endVal, 0.0);
      expect(updatedTween.elapsed, 0.0);
      expect(updatedTween.currentVal, 10.0); // 10 + (0 - 10) * 0
      expect(updatedTween.isComplete, isFalse);

      tweenSystem.update(0.5); // Halfway through pong
      expect(updatedTween.elapsed, 0.5);
      expect(updatedTween.currentVal, 5.0); // 10 + (0 - 10) * 0.5
      expect(updatedTween.isComplete, isFalse);
    });

    test('repeat loop mode resets elapsed', () {
      final tween = Tween.create(
        targetProperty: 0,
        startVal: 0.0,
        endVal: 10.0,
        duration: 1.0,
        easingType: TweenEasingType.linear,
        loopMode: TweenLoopMode.repeat,
      );
      tweenCaste.add(1, tween);

      tweenSystem.update(1.5); // Over by 0.5
      final updatedTween = tweenCaste.get(1)!;

      expect(updatedTween.elapsed, 0.5); // 1.5 % 1.0
      expect(updatedTween.currentVal, 5.0); // 0 + 10 * 0.5
      expect(updatedTween.isComplete, isFalse);

      // Values shouldn't swap
      expect(updatedTween.startVal, 0.0);
      expect(updatedTween.endVal, 10.0);
    });

    test('handles zero duration properly', () {
      final tween = Tween.create(
        targetProperty: 0,
        startVal: 0.0,
        endVal: 10.0,
        duration: 0.0,
        easingType: TweenEasingType.linear,
        loopMode: TweenLoopMode.once,
      );
      tweenCaste.add(1, tween);

      tweenSystem.update(0.1);
      final updatedTween = tweenCaste.get(1)!;

      // Should immediately jump to end
      expect(updatedTween.currentVal, 10.0);
      expect(updatedTween.isComplete, isTrue);
    });
  });
}
