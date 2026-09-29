import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/components/floating_text.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/systems/floating_text_system.dart';
import 'dart:ui';

void main() {
  group('FloatingTextSystem', () {
    late ComponentStorage<FloatingText> textCaste;
    late ComponentStorage<Viewport> viewportCaste;
    late FloatingTextSystem system;
    late PictureRecorder recorder;
    late Canvas canvas;

    setUp(() {
      textCaste = ComponentStorage<FloatingText>(100);
      viewportCaste = ComponentStorage<Viewport>(1);
      system = FloatingTextSystem(
        floatingTextCaste: textCaste,
        viewportCaste: viewportCaste,
        gravity: 10.0,
      );
      recorder = PictureRecorder();
      canvas = Canvas(recorder);

      viewportCaste.add(0, Viewport.create(100.0, 100.0, 1.0));
    });

    test('update() modifies positions based on velocity, gravity, and dt', () {
      final text = FloatingText.create(
          10.0, 20.0, 50.0, -20.0, 1.0, 1.0, 1.0, 1.0, 100.0);
      textCaste.add(1, text);

      system.update(0.1);

      // velocityY: -20 + 10 * 0.1 = -19.0
      // worldX: 10 + (50 * 0.1) = 15
      // worldY: 20 + (-19 * 0.1) = 18.1
      expect(text.velocityY, closeTo(-19.0, 0.001));
      expect(text.worldX, closeTo(15.0, 0.001));
      expect(text.worldY, closeTo(18.1, 0.001));
    });

    test('update() updates lifetime and alpha correctly', () {
      final text =
          FloatingText.create(0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 1.0, 1.0, 99.0);
      textCaste.add(1, text);

      system.update(1.0); // Half life

      expect(text.lifetime, closeTo(1.0, 0.001));
      expect(text.alpha, closeTo(0.5, 0.001));
    });

    test('render() correctly accesses pre-cached paragraphs without crashing',
        () {
      system.preCacheNumbers(10);
      final text =
          FloatingText.create(100.0, 100.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 5.0);
      textCaste.add(1, text);

      expect(() => system.render(canvas), returnsNormally);
    });

    test('render() skips if lifetime <= 0', () {
      final text =
          FloatingText.create(100.0, 100.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 42.0);
      textCaste.add(1, text);

      expect(() => system.render(canvas), returnsNormally);
    });
  });
}
