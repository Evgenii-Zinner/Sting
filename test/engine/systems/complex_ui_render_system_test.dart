import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/complex_ui.dart';
import 'package:sting/engine/systems/complex_ui_render_system.dart';

class MockCanvas extends Fake implements Canvas {
  int drawPathCount = 0;
  int drawParagraphCount = 0;

  @override
  void drawPath(Path path, Paint paint) {
    drawPathCount++;
  }

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {
    drawParagraphCount++;
  }
}

void main() {
  group('ComplexUIRenderSystem', () {
    late Swarm swarm;
    late ComponentCaste<ComplexUI> uiCaste;
    late ComplexUIRenderSystem system;
    late MockCanvas canvas;

    setUp(() {
      swarm = Swarm();
      uiCaste = ComponentCaste<ComplexUI>(10);
      system = ComplexUIRenderSystem(complexUICaste: uiCaste);
      canvas = MockCanvas();
    });

    test('Renders panel without text', () {
      final entity = swarm.createEntity();
      final ui = ComplexUI(width: 100, height: 100);
      uiCaste.add(entity, ui);

      system.render(canvas);

      expect(canvas.drawPathCount, 1);
      expect(canvas.drawParagraphCount, 0);
      expect(ui.isDirty, isFalse);
      expect(ui.cachedPath, isNotNull);
      expect(ui.cachedPaint, isNotNull);
      expect(ui.cachedParagraph, isNull);
    });

    test('Renders button with text', () {
      final entity = swarm.createEntity();
      final ui = ComplexUI(text: 'Click Me');
      uiCaste.add(entity, ui);

      system.render(canvas);

      expect(canvas.drawPathCount, 1);
      expect(canvas.drawParagraphCount, 1);
      expect(ui.isDirty, isFalse);
      expect(ui.cachedParagraph, isNotNull);
    });

    test('Rebuilds cached objects only when dirty', () {
      final entity = swarm.createEntity();
      final ui = ComplexUI(text: 'Click Me');
      uiCaste.add(entity, ui);

      system.render(canvas);

      final firstPath = ui.cachedPath;
      final firstParagraph = ui.cachedParagraph;

      // Render again without making changes
      canvas = MockCanvas();
      system.render(canvas);

      expect(canvas.drawPathCount, 1);
      expect(canvas.drawParagraphCount, 1);

      // Cached objects should be identical (no rebuild)
      expect(identical(ui.cachedPath, firstPath), isTrue);
      expect(identical(ui.cachedParagraph, firstParagraph), isTrue);

      // Make dirty
      ui.width = 200;
      expect(ui.isDirty, isTrue);

      // Render again
      canvas = MockCanvas();
      system.render(canvas);

      expect(canvas.drawPathCount, 1);
      expect(canvas.drawParagraphCount, 1);

      // Cached objects should have been rebuilt
      expect(identical(ui.cachedPath, firstPath), isFalse);
      expect(identical(ui.cachedParagraph, firstParagraph), isFalse);
    });
  });
}
