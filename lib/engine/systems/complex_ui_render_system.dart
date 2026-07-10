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
        // Build the path relative to (0,0) to avoid rebuilding on position change
        final path = Path();
        final rect = Rect.fromLTWH(0, 0, complexUI.width, complexUI.height);

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
              (complexUI.height - complexUI.cachedParagraph!.height) / 2.0;
          complexUI.updateCachedOffset(0, textY);
        } else {
          complexUI.cachedParagraph = null;
        }

        complexUI.clearDirty();
      }

      canvas.save();
      canvas.translate(complexUI.x, complexUI.y);

      // Draw the cached path using the cached paint
      if (complexUI.cachedPath != null &&
          complexUI.cachedPaint != null &&
          ((complexUI.backgroundColor >> 24) & 0xFF) > 0) {
        canvas.drawPath(complexUI.cachedPath!, complexUI.cachedPaint!);
      }

      // Draw the cached paragraph
      if (complexUI.cachedParagraph != null) {
        canvas.drawParagraph(
            complexUI.cachedParagraph!, complexUI.cachedOffset);
      }

      canvas.restore();
    });
  }
}
