import 'dart:ui';
import '../ecs/query.dart';
import '../ecs/component_caste.dart';
import '../components/text_render.dart';

/// Renders [TextRender] components directly to the canvas using dart:ui.
///
/// Overrides world coordinates to stay static on screen.
/// Adheres to zero-allocation per frame constraint by only building paragraphs
/// when the component is dirty (e.g., text or color changes).
class TextRenderSystem {
  final Query1<TextRender> query;

  /// Creates a new [TextRenderSystem].
  TextRenderSystem({
    required ComponentCaste<TextRender> textRenderCaste,
  }) : query = Query1<TextRender>(textRenderCaste);

  /// Renders all text components to the [canvas].
  void render(Canvas canvas) {
    query.forEach((entity, textRender) {
      if (textRender.isDirty || textRender.cachedParagraph == null) {
        // Rebuild paragraph if text or styling changed
        final builder = ParagraphBuilder(ParagraphStyle(
          fontSize: textRender.fontSize,
        ));

        builder.pushStyle(TextStyle(color: Color(textRender.color)));
        builder.addText(textRender.text);

        final paragraph = builder.build();
        // Layout with unconstrained width
        paragraph.layout(const ParagraphConstraints(width: double.infinity));

        textRender.cachedParagraph = paragraph;
        textRender.clearDirty();
      }

      // Draw the cached paragraph at the cached offset
      canvas.drawParagraph(
          textRender.cachedParagraph!, textRender.cachedOffset);
    });
  }
}
