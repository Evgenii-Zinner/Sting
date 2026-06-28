import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/engine/components/sprite_animation.dart';

void main() {
  group('SpriteAnimation Component', () {
    test('create initializes values correctly', () {
      final anim = SpriteAnimation.create(0.1, 8);

      expect(anim.currentFrameIndex, equals(0));
      expect(anim.frameDuration, closeTo(0.1, 0.0001));
      expect(anim.elapsedTime, equals(0.0));
      expect(anim.frameCount, equals(8));

      // Underlying data check
      expect(anim.data.length, equals(4));
    });

    test('getters and setters work correctly', () {
      final anim = SpriteAnimation.create(0.1, 8);

      anim.currentFrameIndex = 3;
      expect(anim.currentFrameIndex, equals(3));

      anim.frameDuration = 0.2;
      expect(anim.frameDuration, closeTo(0.2, 0.0001));

      anim.elapsedTime = 0.05;
      expect(anim.elapsedTime, closeTo(0.05, 0.0001));

      anim.frameCount = 10;
      expect(anim.frameCount, equals(10));
    });

    test('is flat and can be constructed from existing list', () {
      final list = Float32List.fromList([2.0, 0.15, 0.1, 6.0]);
      final anim = SpriteAnimation(list);

      expect(anim.currentFrameIndex, equals(2));
      expect(anim.frameDuration, closeTo(0.15, 0.0001));
      expect(anim.elapsedTime, closeTo(0.1, 0.0001));
      expect(anim.frameCount, equals(6));
    });
  });
}
