import 'dart:ui';

import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/progress_bar.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';

/// Renders ProgressBar components and smoothly updates their visual state.
class ProgressBarRenderSystem {
  final ComponentStorage<ProgressBar> progressBars;
  final ComponentStorage<Position>? positions;
  final ComponentStorage<Viewport>? viewports;

  final Paint _bgPaint = Paint()..style = PaintingStyle.fill;
  final Paint _ghostPaint = Paint()..style = PaintingStyle.fill;
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _borderPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _segmentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFF000000);

  ProgressBarRenderSystem(
    this.progressBars, {
    this.positions,
    this.viewports,
  });

  /// Updates the `visualValue` to smoothly catch up to `currentValue`.
  void update(double dt) {
    Query1<ProgressBar>(progressBars).forEach((entity, bar) {
      if (bar.visualValue != bar.currentValue) {
        final diff = bar.currentValue - bar.visualValue;
        final step = diff * (bar.catchUpSpeed * dt).clamp(0.0, 1.0);

        bar.visualValue += step;

        if ((bar.currentValue - bar.visualValue).abs() < 0.1) {
          bar.visualValue = bar.currentValue;
        }
      }
    });
  }

  /// Renders all progress bars without per-frame allocations.
  void render(Canvas canvas) {
    Viewport? viewport;
    if (viewports != null && viewports!.length > 0) {
      viewport = viewports!.getAt(0);
    }

    Query1<ProgressBar>(progressBars).forEach((entity, bar) {
      double renderX = bar.offsetX;
      double renderY = bar.offsetY;

      // Handle World Space mapping if position exists
      if (bar.isWorldSpace > 0.0 && positions != null) {
        final pos = positions!.get(entity);
        if (pos != null) {
          renderX += pos.x;
          renderY += pos.y;

          if (viewport != null) {
            final scale = viewport.zoom;
            // Prevent sub-pixel jitter
            renderX = ((renderX - viewport.x) * scale).roundToDouble() / scale +
                viewport.x;
            renderY = ((renderY - viewport.y) * scale).roundToDouble() / scale +
                viewport.y;
          }
        }
      }

      final w = bar.width;
      final h = bar.height;
      final r = bar.borderRadius;

      // Ensure colors are updated correctly from the component data without re-allocating if unchanged
      final bgCol = bar.backgroundColorHex.toInt();
      if (_bgPaint.color.toARGB32() != bgCol) _bgPaint.color = Color(bgCol);

      final ghostCol = bar.ghostColorHex.toInt();
      if (_ghostPaint.color.toARGB32() != ghostCol) {
        _ghostPaint.color = Color(ghostCol);
      }

      final fillCol = bar.fillColorHex.toInt();
      if (_fillPaint.color.toARGB32() != fillCol) {
        _fillPaint.color = Color(fillCol);
      }

      final borderCol = bar.borderColorHex.toInt();
      if (_borderPaint.color.toARGB32() != borderCol) {
        _borderPaint.color = Color(borderCol);
      }

      _borderPaint.strokeWidth = bar.borderWidth;

      // Calculate widths
      final maxV = bar.maxValue > 0 ? bar.maxValue : 1.0;
      final targetRatio = bar.ratio;
      final visualRatio = (bar.visualValue / maxV).clamp(0.0, 1.0);

      final fillWidth = w * targetRatio;
      final ghostWidth = w * visualRatio;

      canvas.save();
      canvas.translate(renderX, renderY);

      if (r > 0) {
        // Draw Rounded Rects
        final bgRRect = RRect.fromLTRBR(0, 0, w, h, Radius.circular(r));
        canvas.drawRRect(bgRRect, _bgPaint);

        if (visualRatio > targetRatio && ghostWidth > 0) {
          final ghostRRect =
              RRect.fromLTRBR(0, 0, ghostWidth, h, Radius.circular(r));
          canvas.drawRRect(ghostRRect, _ghostPaint);
        }

        if (fillWidth > 0) {
          final fillRRect =
              RRect.fromLTRBR(0, 0, fillWidth, h, Radius.circular(r));
          canvas.drawRRect(fillRRect, _fillPaint);
        }

        if (bar.borderWidth > 0) {
          canvas.drawRRect(bgRRect, _borderPaint);
        }
      } else {
        // Draw standard Rects
        final bgRect = Rect.fromLTRB(0, 0, w, h);
        canvas.drawRect(bgRect, _bgPaint);

        if (visualRatio > targetRatio && ghostWidth > 0) {
          final ghostRect = Rect.fromLTRB(0, 0, ghostWidth, h);
          canvas.drawRect(ghostRect, _ghostPaint);
        }

        if (fillWidth > 0) {
          final fillRect = Rect.fromLTRB(0, 0, fillWidth, h);
          canvas.drawRect(fillRect, _fillPaint);
        }

        if (bar.borderWidth > 0) {
          canvas.drawRect(bgRect, _borderPaint);
        }
      }

      // Draw Segments if any
      if (bar.segments > 1.0) {
        final segments = bar.segments.toInt();
        final segmentWidth = w / segments;
        _segmentPaint.strokeWidth = bar.borderWidth > 0 ? bar.borderWidth : 1.0;

        for (int i = 1; i < segments; i++) {
          final sx = segmentWidth * i;
          canvas.drawLine(Offset(sx, 0), Offset(sx, h), _segmentPaint);
        }
      }

      canvas.restore();
    });
  }
}
