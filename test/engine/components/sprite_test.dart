import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/ecs/component_caste.dart';

void main() {
  group('Sprite Component', () {
    test('create initializes values to zero', () {
      final sprite = Sprite.create();

      expect(sprite.rectLeft, 0.0);
      expect(sprite.rectTop, 0.0);
      expect(sprite.rectRight, 0.0);
      expect(sprite.rectBottom, 0.0);

      expect(sprite.transformScos, 0.0);
      expect(sprite.transformSsin, 0.0);
      expect(sprite.transformTx, 0.0);
      expect(sprite.transformTy, 0.0);

      expect(sprite.color, 0);
    });

    test('getters and setters update underlying memory for rect', () {
      final sprite = Sprite.create();

      sprite.rectLeft = 10.0;
      sprite.rectTop = 20.0;
      sprite.rectRight = 30.0;
      sprite.rectBottom = 40.0;

      expect(sprite.rectLeft, 10.0);
      expect(sprite.rectTop, 20.0);
      expect(sprite.rectRight, 30.0);
      expect(sprite.rectBottom, 40.0);
    });

    test('getters and setters update underlying memory for transform', () {
      final sprite = Sprite.create();

      sprite.transformScos = 1.0;
      sprite.transformSsin = 0.5;
      sprite.transformTx = 100.0;
      sprite.transformTy = -50.0;

      expect(sprite.transformScos, 1.0);
      expect(sprite.transformSsin, 0.5);
      expect(sprite.transformTx, 100.0);
      expect(sprite.transformTy, -50.0);
    });

    test('getters and setters update underlying memory for color', () {
      final sprite = Sprite.create();

      // Assuming a 32-bit ARGB color value: 0xAARRGGBB
      final colorValue = 0xFFFF0000; // Red
      sprite.color = colorValue;

      expect(sprite.color, colorValue);
    });

    test('can be stored in ComponentCaste without issues', () {
      final caste = ComponentCaste<Sprite>(10);

      final sprite1 = Sprite.create();
      sprite1.rectLeft = 5.0;
      sprite1.color = 0xFF00FF00;

      final sprite2 = Sprite.create();
      sprite2.rectTop = 15.0;
      sprite2.color = 0xFF0000FF;

      caste.add(0, sprite1);
      caste.add(1, sprite2);

      final retrievedSprite1 = caste.get(0);
      final retrievedSprite2 = caste.get(1);

      expect(retrievedSprite1, isNotNull);
      expect(retrievedSprite1!.rectLeft, 5.0);
      expect(retrievedSprite1.color, 0xFF00FF00);

      expect(retrievedSprite2, isNotNull);
      expect(retrievedSprite2!.rectTop, 15.0);
      expect(retrievedSprite2.color, 0xFF0000FF);

      // Modification through retrieved reference should mutate the stored structure
      retrievedSprite1.transformTx = 99.0;
      expect(caste.get(0)!.transformTx, 99.0);
    });
  });
}
