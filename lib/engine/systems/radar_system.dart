import 'dart:math';
import 'dart:ui';

import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/radar_display.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';

/// A system that manages and renders RadarDisplay components.
/// Allows for real-time tactical radar and minimap visualization.
class RadarSystem {
  final ComponentStorage<RadarDisplay> _radarCaste;

  final Paint _bgPaint;
  final Paint _gridPaint;
  final Paint _blipPaint;
  final Paint _sweepPaint;

  /// Creates a RadarSystem.
  RadarSystem({
    required ComponentStorage<RadarDisplay> radarCaste,
  })  : _radarCaste = radarCaste,
        _bgPaint = Paint()..style = PaintingStyle.fill,
        _gridPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
        _blipPaint = Paint()..style = PaintingStyle.fill,
        _sweepPaint = Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 2.0;

  /// Updates the sweep angles for all radars.
  /// Zero allocations per frame.
  void update(double dt) {
    final length = _radarCaste.length;
    for (var i = 0; i < length; i++) {
      final radar = _radarCaste.getComponentAt(i);
      if (radar != null) {
        radar.sweepAngle = (radar.sweepAngle + radar.sweepSpeed * dt) % (2 * pi);
      }
    }
  }

  /// Renders all radar displays onto the canvas.
  /// Queries [blipsQuery] to find entities with Position components within the radar's world range.
  /// Strictly zero heap allocations per frame.
  void render(
    Canvas canvas,
    double centerWorldX,
    double centerWorldY,
    Query1<Position> blipsQuery,
  ) {
    final length = _radarCaste.length;
    for (var i = 0; i < length; i++) {
      final radar = _radarCaste.getComponentAt(i);
      if (radar != null) {
        _renderRadar(canvas, centerWorldX, centerWorldY, radar, blipsQuery);
      }
    }
  }

  void _renderRadar(
    Canvas canvas,
    double centerWorldX,
    double centerWorldY,
    RadarDisplay radar,
    Query1<Position> blipsQuery,
  ) {
    // Configure paints
    _bgPaint.color = Color(radar.backgroundColorHex);
    _gridPaint.color = Color(radar.radarColorHex);
    _blipPaint.color = Color(radar.blipColorHex);
    _sweepPaint.color = Color(radar.radarColorHex).withAlpha(128); // semi-transparent sweep

    final sx = radar.screenX;
    final sy = radar.screenY;
    final r = radar.radius;
    final isCircular = radar.isCircular == 1.0;

    // Draw background
    if (isCircular) {
      canvas.drawCircle(Offset(sx, sy), r, _bgPaint);

      // Draw range rings
      canvas.drawCircle(Offset(sx, sy), r, _gridPaint);
      canvas.drawCircle(Offset(sx, sy), r * 0.66, _gridPaint);
      canvas.drawCircle(Offset(sx, sy), r * 0.33, _gridPaint);
    } else {
      final rect = Rect.fromLTRB(sx - r, sy - r, sx + r, sy + r);
      canvas.drawRect(rect, _bgPaint);
      canvas.drawRect(rect, _gridPaint);

      // Grid lines
      canvas.drawLine(Offset(sx - r, sy - r * 0.33), Offset(sx + r, sy - r * 0.33), _gridPaint);
      canvas.drawLine(Offset(sx - r, sy + r * 0.33), Offset(sx + r, sy + r * 0.33), _gridPaint);
      canvas.drawLine(Offset(sx - r * 0.33, sy - r), Offset(sx - r * 0.33, sy + r), _gridPaint);
      canvas.drawLine(Offset(sx + r * 0.33, sy - r), Offset(sx + r * 0.33, sy + r), _gridPaint);
    }

    // Draw sweep line
    final sweepEndX = sx + r * cos(radar.sweepAngle);
    final sweepEndY = sy + r * sin(radar.sweepAngle);
    canvas.drawLine(Offset(sx, sy), Offset(sweepEndX, sweepEndY), _gridPaint);

    // Sweep cone (optional, keeping it zero-allocation might be tricky with Path without pre-allocating,
    // so a simple line or sweep brush approach is used).

    // Draw blips
    final double maxRange = radar.worldRange;
    final double maxRangeSq = maxRange * maxRange;

    // Scale factor from world to screen
    final double scale = r / maxRange;

    blipsQuery.forEach((entity, position) {
      final double dx = position.x - centerWorldX;
      final double dy = position.y - centerWorldY;

      final double distSq = dx * dx + dy * dy;
      if (distSq <= maxRangeSq) {
        final double blipX = sx + dx * scale;
        final double blipY = sy + dy * scale;

        if (isCircular) {
          // It's already within maxRange, so it's guaranteed within the circle
          canvas.drawCircle(Offset(blipX, blipY), 2.0, _blipPaint);
        } else {
          // Clamp to rect if we want square radar, though if maxRange is circular we just check bounds
          if (blipX >= sx - r && blipX <= sx + r && blipY >= sy - r && blipY <= sy + r) {
            canvas.drawRect(Rect.fromLTRB(blipX - 2, blipY - 2, blipX + 2, blipY + 2), _blipPaint);
          }
        }
      }
    });
  }
}
