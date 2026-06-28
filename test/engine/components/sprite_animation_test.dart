import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/engine/components/sprite_animation.dart';

void main() {
  group('SpriteAnimation Component', () {
    test('create initializes values correctly', () {
      final anim = SpriteAnimation.create(
        0.1,
        8,
        frameWidth: 32.0,
        frameHeight: 64.0,
        startX: 10.0,
        startY: 20.0,
      );

      expect(anim.currentFrameIndex, equals(0));
      expect(anim.frameDuration, closeTo(0.1, 0.0001));
      expect(anim.elapsedTime, equals(0.0));
      expect(anim.frameCount, equals(8));
      expect(anim.frameWidth, closeTo(32.0, 0.0001));
      expect(anim.frameHeight, closeTo(64.0, 0.0001));
      expect(anim.startX, closeTo(10.0, 0.0001));
      expect(anim.startY, closeTo(20.0, 0.0001));

      // Underlying data check
      expect(anim.data.length, equals(8));
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

      anim.frameWidth = 16.0;
      expect(anim.frameWidth, closeTo(16.0, 0.0001));

      anim.frameHeight = 16.0;
      expect(anim.frameHeight, closeTo(16.0, 0.0001));

      anim.startX = 5.0;
      expect(anim.startX, closeTo(5.0, 0.0001));

      anim.startY = 5.0;
      expect(anim.startY, closeTo(5.0, 0.0001));
    });

    test('is flat and can be constructed from existing list', () {
      final list = Float32List.fromList([2.0, 0.15, 0.1, 6.0, 32.0, 32.0, 0.0, 0.0]);
      final anim = SpriteAnimation(list);

      expect(anim.currentFrameIndex, equals(2));
      expect(anim.frameDuration, closeTo(0.15, 0.0001));
      expect(anim.elapsedTime, closeTo(0.1, 0.0001));
      expect(anim.frameCount, equals(6));
      expect(anim.frameWidth, closeTo(32.0, 0.0001));
      expect(anim.frameHeight, closeTo(32.0, 0.0001));
      expect(anim.startX, closeTo(0.0, 0.0001));
      expect(anim.startY, closeTo(0.0, 0.0001));
    });
  });
}
