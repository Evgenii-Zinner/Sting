import 'dart:math';
import 'dart:ui';

import 'package:sting/engine/components/radial_dial.dart';
import 'package:sting/engine/ecs/component_storage.dart';

/// Renders and handles interaction for RadialDial components.
class RadialDialSystem {
  final ComponentStorage<RadialDial> _dials;
  final Paint _trackPaint;
  final Paint _fillPaint;
  final Paint _handlePaint;

  RadialDialSystem(this._dials)
      : _trackPaint = Paint()..style = PaintingStyle.stroke,
        _fillPaint = Paint()..style = PaintingStyle.stroke,
        _handlePaint = Paint()..style = PaintingStyle.fill;

  /// Checks if a pointer down event hits a dial, marking it as dragging.
  /// Returns true if a dial was hit.
  bool handlePointerDown(double px, double py) {
    bool hit = false;
    final length = _dials.length;
    for (int i = 0; i < length; i++) {
      final dial = _dials.getComponentAt(i);
      if (dial == null) continue;

      final dx = px - dial.centerX;
      final dy = py - dial.centerY;
      final distSq = dx * dx + dy * dy;

      final innerSq = dial.innerRadius * dial.innerRadius;
      final outerSq = dial.outerRadius * dial.outerRadius;

      if (distSq >= innerSq && distSq <= outerSq) {
        dial.isDragging = 1.0;
        hit = true;
        _updateValueFromPointer(dial, px, py);
      }
    }
    return hit;
  }

  /// Updates dragged dials based on pointer movement.
  void handlePointerMove(double px, double py) {
    final length = _dials.length;
    for (int i = 0; i < length; i++) {
      final dial = _dials.getComponentAt(i);
      if (dial == null) continue;

      if (dial.isDragging > 0.0) {
        _updateValueFromPointer(dial, px, py);
      }
    }
  }

  /// Releases dragged dials on pointer up.
  void handlePointerUp(double px, double py) {
    final length = _dials.length;
    for (int i = 0; i < length; i++) {
      final dial = _dials.getComponentAt(i);
      if (dial != null) {
        dial.isDragging = 0.0;
      }
    }
  }

  void _updateValueFromPointer(RadialDial dial, double px, double py) {
    final dx = px - dial.centerX;
    final dy = py - dial.centerY;

    // Calculate angle in radians
    double angle = atan2(dy, dx);

    // Normalize to 0 .. 2pi for easier mapping if start/end wraps
    // Actually, mapping between startAngle and endAngle requires handling wrap-around.
    // For simplicity, let's normalize angle to be relative to startAngle
    double start = dial.startAngle;
    double end = dial.endAngle;

    // If end is less than start, it means it wraps around 2PI
    if (end < start) {
      end += 2 * pi;
    }

    while (angle < start) {
      angle += 2 * pi;
    }

    if (angle > end) {
      // It's outside the range, determine which bound is closer
      final distToStart = (angle - start).abs();
      final distToEnd = (angle - end).abs();

      // Also consider wrap around distance
      final distToStartWrap = (angle - (start + 2 * pi)).abs();
      final distToEndWrap = (angle - (end + 2 * pi)).abs();

      final minToStart = min(distToStart, distToStartWrap);
      final minToEnd = min(distToEnd, distToEndWrap);

      if (minToStart < minToEnd) {
        angle = start;
      } else {
        angle = end;
      }
    }

    double t = (angle - start) / (end - start);

    if (t < 0.0) t = 0.0;
    if (t > 1.0) t = 1.0;

    if (dial.segments > 1.0) {
      final segments = dial.segments.toInt();
      t = (t * segments).roundToDouble() / segments;
    }

    dial.currentValue = t;
  }

  /// Renders all dials to the canvas.
  void render(Canvas canvas) {
    final length = _dials.length;
    for (int i = 0; i < length; i++) {
      final dial = _dials.getComponentAt(i);
      if (dial == null) continue;

      final center = Offset(dial.centerX, dial.centerY);
      final strokeWidth = dial.outerRadius - dial.innerRadius;
      final radius = dial.innerRadius + strokeWidth / 2.0;
      final rect = Rect.fromCircle(center: center, radius: radius);

      _trackPaint.color = Color(dial.trackColorHex.toInt());
      _trackPaint.strokeWidth = strokeWidth;

      _fillPaint.color = Color(dial.fillColorHex.toInt());
      _fillPaint.strokeWidth = strokeWidth;

      final startAngle = dial.startAngle;
      final sweepAngle = dial.endAngle - dial.startAngle;

      // Draw track
      canvas.drawArc(rect, startAngle, sweepAngle, false, _trackPaint);

      // Draw fill
      final fillSweep = sweepAngle * dial.currentValue;
      canvas.drawArc(rect, startAngle, fillSweep, false, _fillPaint);

      // Draw handle
      _handlePaint.color = Color(dial.handleColorHex.toInt());
      final currentAngle = startAngle + fillSweep;
      final handleX = dial.centerX + cos(currentAngle) * radius;
      final handleY = dial.centerY + sin(currentAngle) * radius;

      canvas.drawCircle(Offset(handleX, handleY), strokeWidth / 2.0, _handlePaint);
    }
  }
}
