import 'dart:ui';
import '../ecs/query.dart';
import '../ecs/component_caste.dart';
import '../components/complex_ui.dart';

/// Renders [ComplexUI] components to the canvas using dart:ui.
///
/// Overrides world coordinates to stay static on screen.
/// Adheres to zero-allocation per frame constraint by only building paths, paints,
/// and paragraphs when the component is dirty (e.g., properties change).
class ComplexUIRenderSystem {
  final Query1<ComplexUI> query;

  /// Creates a new [ComplexUIRenderSystem].
  ComplexUIRenderSystem({
    required ComponentCaste<ComplexUI> complexUICaste,
  }) : query = Query1<ComplexUI>(complexUICaste);

  /// Renders all complex UI components to the [canvas].
  void render(Canvas canvas) {
    query.forEach((entity, complexUI) {
      if (complexUI.isDirty ||
          complexUI.cachedPath == null ||
          complexUI.cachedPaint == null) {
        // 1. Rebuild Paint
        final paint = Paint()..color = Color(complexUI.backgroundColor);
        complexUI.cachedPaint = paint;

        // 2. Rebuild Path
        final path = Path();
        final rect = Rect.fromLTWH(
            complexUI.x, complexUI.y, complexUI.width, complexUI.height);

        if (complexUI.borderRadius > 0) {
          path.addRRect(RRect.fromRectAndRadius(
              rect, Radius.circular(complexUI.borderRadius)));
        } else {
          path.addRect(rect);
        }
        complexUI.cachedPath = path;

        // 3. Rebuild Paragraph (if there is text)
        if (complexUI.text.isNotEmpty) {
          final builder = ParagraphBuilder(ParagraphStyle(
            fontSize: complexUI.fontSize,
            textAlign: TextAlign.center,
          ));

          builder.pushStyle(TextStyle(color: Color(complexUI.textColor)));
          builder.addText(complexUI.text);

          final paragraph = builder.build();

          // Layout with constrained width so text alignment works within the button bounds
          paragraph.layout(ParagraphConstraints(width: complexUI.width));

          complexUI.cachedParagraph = paragraph;

          // Update the cached offset to be vertically centered
          final textY =
              complexUI.y + (complexUI.height - paragraph.height) / 2.0;
          complexUI.updateCachedOffset(complexUI.x, textY);
        } else {
          complexUI.cachedParagraph = null;
        }

        complexUI.clearDirty();
      }

      // Draw the cached path using the cached paint
      if (complexUI.cachedPath != null && complexUI.cachedPaint != null) {
        canvas.drawPath(complexUI.cachedPath!, complexUI.cachedPaint!);
      }

      // Draw the cached paragraph
      if (complexUI.cachedParagraph != null) {
        canvas.drawParagraph(
            complexUI.cachedParagraph!, complexUI.cachedOffset);
      }
    });
  }
}
