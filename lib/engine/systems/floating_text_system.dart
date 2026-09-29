import 'dart:ui';
import '../ecs/query.dart';
import '../ecs/component_storage.dart';
import '../components/floating_text.dart';
import '../components/viewport.dart';

/// A system that manages the update and rendering of FloatingText components.
/// Ensures zero per-frame object allocations.
class FloatingTextSystem {
  final ComponentStorage<FloatingText> floatingTextCaste;
  final ComponentStorage<Viewport> viewportCaste;
  final double gravity;

  final Query1<FloatingText> _textQuery;

  /// A pre-allocated cache for paragraphs. We'll cache by the integer value of numberValue.
  /// This prevents allocating ParagraphBuilder and Paragraph every frame.
  final Map<int, Paragraph> _paragraphCache = {};

  /// Pre-allocated paint objects for 256 alpha levels to support visual fading
  /// without allocating Paint or Rect objects per frame.
  final List<Paint> _alphaPaints = List.generate(256, (i) => Paint()..color = Color.fromARGB(i, 255, 255, 255));

  /// Creates a FloatingTextSystem.
  FloatingTextSystem({
    required this.floatingTextCaste,
    required this.viewportCaste,
    this.gravity = 150.0,
  }) : _textQuery = Query1<FloatingText>(floatingTextCaste);

  /// Pre-caches numbers from 0 to [maxCacheValue] to prevent allocations during gameplay.
  void preCacheNumbers(int maxCacheValue, {double fontSize = 16.0, int color = 0xFFFFFFFF}) {
    for (int i = 0; i <= maxCacheValue; i++) {
      _paragraphCache[i] = _buildParagraph(i.toString(), fontSize, color);
    }
  }

  Paragraph _buildParagraph(String text, double fontSize, int color) {
     final builder = ParagraphBuilder(ParagraphStyle(
        fontSize: fontSize,
      ));
      builder.pushStyle(TextStyle(color: Color(color)));
      builder.addText(text);
      final paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: double.infinity));
      return paragraph;
  }

  /// Updates the lifetime, alpha, and positions of the floating text.
  void update(double dt) {
    _textQuery.forEach((entity, text) {
      if (text.lifetime > 0) {
        text.lifetime -= dt;

        // Apply vertical gravity / drift
        text.velocityY += gravity * dt;

        text.worldX += text.velocityX * dt;
        text.worldY += text.velocityY * dt;

        double a = text.lifetime / text.maxLifetime;
        if (a < 0.0) a = 0.0;
        if (a > 1.0) a = 1.0;
        text.alpha = a;
      }
    });
  }

  /// Renders active floating texts using the viewport for translation.
  void render(Canvas canvas) {
    Viewport? activeViewport;

    // Find the first available viewport
    for (int i = 0; i < viewportCaste.length; i++) {
      activeViewport = viewportCaste.getComponentAt(i);
      if (activeViewport != null) {
        break;
      }
    }

    if (activeViewport == null) return;

    final double vX = activeViewport.x;
    final double vY = activeViewport.y;
    final double zoom = activeViewport.zoom;

    _textQuery.forEach((entity, text) {
      if (text.lifetime > 0 && text.alpha > 0) {
        int intValue = text.numberValue.toInt();

        // Fetch or create paragraph
        Paragraph? paragraph = _paragraphCache[intValue];
        if (paragraph == null) {
          paragraph = _buildParagraph(intValue.toString(), 16.0, 0xFFFFFFFF);
          _paragraphCache[intValue] = paragraph;
        }

        // Calculate screen position
        double screenX = (text.worldX - vX) * zoom;
        double screenY = (text.worldY - vY) * zoom;

        canvas.save();
        canvas.translate(screenX, screenY);
        if (text.scale != 1.0) {
          canvas.scale(text.scale, text.scale);
        }

        // Apply visual fading using pre-allocated paints
        int alphaInt = (text.alpha * 255).round().clamp(0, 255);
        if (alphaInt < 255) {
          canvas.saveLayer(null, _alphaPaints[alphaInt]);
        }

        canvas.drawParagraph(paragraph, Offset.zero);

        if (alphaInt < 255) {
          canvas.restore();
        }

        canvas.restore();
      }
    });
  }
}

