import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/text_render.dart';
import 'package:sting/engine/systems/text_render_system.dart';
import 'dart:ui';

void main() {
  group('TextRenderSystem', () {
    late ComponentCaste<TextRender> textRenderCaste;
    late TextRenderSystem textRenderSystem;
    late PictureRecorder recorder;
    late Canvas canvas;

    setUp(() {
      textRenderCaste = ComponentCaste<TextRender>(100);
      textRenderSystem = TextRenderSystem(textRenderCaste: textRenderCaste);
      recorder = PictureRecorder();
      canvas = Canvas(recorder);
    });

    test('builds paragraph and renders correctly on first pass', () {
      final textRender = TextRender(text: 'Score: 100', x: 10.0, y: 20.0);
      textRenderCaste.add(0, textRender);

      expect(textRender.isDirty, isTrue);
      expect(textRender.cachedParagraph, isNull);

      textRenderSystem.render(canvas);

      expect(textRender.isDirty, isFalse);
      expect(textRender.cachedParagraph, isNotNull);
    });

    test('reuses cached paragraph on subsequent passes without allocations',
        () {
      final textRender = TextRender(text: 'Score: 100', x: 10.0, y: 20.0);
      textRenderCaste.add(0, textRender);

      textRenderSystem.render(canvas);

      final cachedParagraph = textRender.cachedParagraph;
      expect(cachedParagraph, isNotNull);
      expect(textRender.isDirty, isFalse);

      // Render again without changing anything
      textRenderSystem.render(canvas);

      // The paragraph should be the exact same object reference
      expect(identical(textRender.cachedParagraph, cachedParagraph), isTrue);
    });

    test('rebuilds paragraph when text changes', () {
      final textRender = TextRender(text: 'Score: 100', x: 10.0, y: 20.0);
      textRenderCaste.add(0, textRender);

      textRenderSystem.render(canvas);

      final firstParagraph = textRender.cachedParagraph;

      textRender.text = 'Score: 200';
      expect(textRender.isDirty, isTrue);

      textRenderSystem.render(canvas);

      expect(textRender.isDirty, isFalse);
      expect(identical(textRender.cachedParagraph, firstParagraph),
          isFalse); // New object
    });

    test('rebuilds paragraph when color changes', () {
      final textRender = TextRender(text: 'Score: 100', color: 0xFFFFFFFF);
      textRenderCaste.add(0, textRender);

      textRenderSystem.render(canvas);

      final firstParagraph = textRender.cachedParagraph;

      textRender.color = 0xFFFF0000;
      expect(textRender.isDirty, isTrue);

      textRenderSystem.render(canvas);

      expect(textRender.isDirty, isFalse);
      expect(identical(textRender.cachedParagraph, firstParagraph),
          isFalse); // New object
    });

    test('does not rebuild paragraph when only position changes', () {
      final textRender = TextRender(text: 'Score: 100', x: 10.0, y: 10.0);
      textRenderCaste.add(0, textRender);

      textRenderSystem.render(canvas);

      final firstParagraph = textRender.cachedParagraph;

      textRender.x = 50.0;
      textRender.y = 50.0;
      expect(textRender.isDirty, isFalse); // Position should not flag dirty

      textRenderSystem.render(canvas);

      // Should still be the identical paragraph object
      expect(identical(textRender.cachedParagraph, firstParagraph), isTrue);
      // But cached offset should be updated
      expect(textRender.cachedOffset, const Offset(50.0, 50.0));
    });

    test('execution completes successfully without exceptions', () {
      textRenderCaste.add(0, TextRender(text: 'Entity 0', x: 10, y: 10));
      textRenderCaste.add(1, TextRender(text: 'Entity 1', x: 20, y: 20));
      textRenderCaste.add(2, TextRender(text: 'Entity 2', x: 30, y: 30));

      // We mainly test that calling render doesn't crash or throw exceptions
      expect(() => textRenderSystem.render(canvas), returnsNormally);

      // Complete recording
      recorder.endRecording();
    });
  });
}
