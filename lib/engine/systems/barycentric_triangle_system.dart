import 'dart:math';
import 'dart:ui';

import 'package:sting/engine/components/barycentric_triangle.dart';
import 'package:sting/engine/ecs/component_storage.dart';

/// Renders and handles interaction for BarycentricTriangle components.
/// Ensures zero per-frame heap allocations during update and event loop.
class BarycentricTriangleSystem {
  final ComponentStorage<BarycentricTriangle> _triangles;

  // Pre-allocated for zero-allocation rendering
  final Paint _strokePaint;
  final Paint _puckPaint;
  final Paint _backdropPaint;
  final Paint _guidePaint;
  final Paint _ringPaint;
  final Paint _cornerPaint;
  final Paint _auraPaint;
  final Path _trianglePath;

  BarycentricTriangleSystem(this._triangles)
      : _strokePaint = Paint()..style = PaintingStyle.stroke,
        _puckPaint = Paint()..style = PaintingStyle.fill,
        _backdropPaint = Paint()..style = PaintingStyle.fill,
        _guidePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0,
        _ringPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.0,
        _cornerPaint = Paint()..style = PaintingStyle.fill,
        _auraPaint = Paint()..style = PaintingStyle.fill,
        _trianglePath = Path();

  /// Checks if a pointer down event hits a triangle, marking it as dragging.
  /// Returns true if a triangle was hit.
  bool handlePointerDown(double px, double py) {
    bool hit = false;
    final length = _triangles.length;
    for (int i = 0; i < length; i++) {
      final tri = _triangles.getComponentAt(i);
      if (tri == null) continue;

      final dx = px - tri.centerX;
      final dy = py - tri.centerY;
      final distSq = dx * dx + dy * dy;

      // Allow hit within a reasonable bounding circle of the triangle.
      final radiusSq = tri.radius * tri.radius;

      if (distSq <= radiusSq) {
        tri.isDragging = 1.0;
        hit = true;
        _updateValueFromPointer(tri, px, py);
      }
    }
    return hit;
  }

  /// Updates dragged triangles based on pointer movement.
  void handlePointerMove(double px, double py) {
    final length = _triangles.length;
    for (int i = 0; i < length; i++) {
      final tri = _triangles.getComponentAt(i);
      if (tri == null) continue;

      if (tri.isDragging > 0.0) {
        _updateValueFromPointer(tri, px, py);
      }
    }
  }

  /// Releases dragged triangles on pointer up.
  void handlePointerUp(double px, double py) {
    final length = _triangles.length;
    for (int i = 0; i < length; i++) {
      final tri = _triangles.getComponentAt(i);
      if (tri != null) {
        tri.isDragging = 0.0;
      }
    }
  }

  void _updateValueFromPointer(BarycentricTriangle tri, double px, double py) {
    // Top vertex (A)
    double aX = 0.0;
    double aY = -tri.radius;
    // Bottom right (B)
    double bX = tri.radius * cos(pi / 6);
    double bY = tri.radius * sin(pi / 6);
    // Bottom left (C)
    double cX = -tri.radius * cos(pi / 6);
    double cY = tri.radius * sin(pi / 6);

    // Apply rotation
    final rot = tri.rotation;
    final cosRot = cos(rot);
    final sinRot = sin(rot);

    // Rotate relative to center
    double rotAx = aX * cosRot - aY * sinRot;
    double rotAy = aX * sinRot + aY * cosRot;
    double rotBx = bX * cosRot - bY * sinRot;
    double rotBy = bX * sinRot + bY * cosRot;
    double rotCx = cX * cosRot - cY * sinRot;
    double rotCy = cX * sinRot + cY * cosRot;

    // Absolute positions
    final aAbsX = tri.centerX + rotAx;
    final aAbsY = tri.centerY + rotAy;
    final bAbsX = tri.centerX + rotBx;
    final bAbsY = tri.centerY + rotBy;
    final cAbsX = tri.centerX + rotCx;
    final cAbsY = tri.centerY + rotCy;

    // Barycentric coordinates
    final det =
        (bAbsY - cAbsY) * (aAbsX - cAbsX) + (cAbsX - bAbsX) * (aAbsY - cAbsY);

    double wA =
        ((bAbsY - cAbsY) * (px - cAbsX) + (cAbsX - bAbsX) * (py - cAbsY)) / det;
    double wB =
        ((cAbsY - aAbsY) * (px - cAbsX) + (aAbsX - cAbsX) * (py - cAbsY)) / det;
    double wC = 1.0 - wA - wB;

    // Clamping logic to equilateral boundary
    if (wA < 0.0 && wB < 0.0) {
      wC = 1.0;
      wA = 0.0;
      wB = 0.0;
    } else if (wB < 0.0 && wC < 0.0) {
      wA = 1.0;
      wB = 0.0;
      wC = 0.0;
    } else if (wC < 0.0 && wA < 0.0) {
      wB = 1.0;
      wC = 0.0;
      wA = 0.0;
    } else if (wA < 0.0) {
      wA = 0.0;
      final bcX = cAbsX - bAbsX;
      final bcY = cAbsY - bAbsY;
      final t =
          ((px - bAbsX) * bcX + (py - bAbsY) * bcY) / (bcX * bcX + bcY * bcY);
      final tClamped = max(0.0, min(1.0, t));
      wC = tClamped;
      wB = 1.0 - wC;
    } else if (wB < 0.0) {
      wB = 0.0;
      final caX = aAbsX - cAbsX;
      final caY = aAbsY - cAbsY;
      final t =
          ((px - cAbsX) * caX + (py - cAbsY) * caY) / (caX * caX + caY * caY);
      final tClamped = max(0.0, min(1.0, t));
      wA = tClamped;
      wC = 1.0 - tClamped;
    } else if (wC < 0.0) {
      wC = 0.0;
      final abX = bAbsX - aAbsX;
      final abY = bAbsY - aAbsY;
      final t =
          ((px - aAbsX) * abX + (py - aAbsY) * abY) / (abX * abX + abY * abY);
      final tClamped = max(0.0, min(1.0, t));
      wB = tClamped;
      wA = 1.0 - tClamped;
    }

    // Double check everything is within 0.0 - 1.0 just in case.
    wA = max(0.0, min(1.0, wA));
    wB = max(0.0, min(1.0, wB));
    wC = max(0.0, min(1.0, wC));

    // And ensure they sum to exactly 1.0 if not already (might be off due to float division).
    double sum = wA + wB + wC;
    if (sum > 0.0) {
      wA /= sum;
      wB /= sum;
      wC /= sum;
    } else {
      wA = 0.3333333;
      wB = 0.3333333;
      wC = 0.3333333;
    }

    tri.weightA = wA;
    tri.weightB = wB;
    tri.weightC = wC;

    tri.puckX = wA * aAbsX + wB * bAbsX + wC * cAbsX;
    tri.puckY = wA * aAbsY + wB * bAbsY + wC * cAbsY;
  }

  /// Renders all triangles to the canvas.
  void render(Canvas canvas) {
    final length = _triangles.length;
    for (int i = 0; i < length; i++) {
      final tri = _triangles.getComponentAt(i);
      if (tri == null) continue;

      // Calculate absolute corners for rendering
      // Top vertex (A)
      double aX = 0.0;
      double aY = -tri.radius;
      // Bottom right (B)
      double bX = tri.radius * cos(pi / 6);
      double bY = tri.radius * sin(pi / 6);
      // Bottom left (C)
      double cX = -tri.radius * cos(pi / 6);
      double cY = tri.radius * sin(pi / 6);

      // Apply rotation
      final rot = tri.rotation;
      final cosRot = cos(rot);
      final sinRot = sin(rot);

      double rotAx = aX * cosRot - aY * sinRot;
      double rotAy = aX * sinRot + aY * cosRot;
      double rotBx = bX * cosRot - bY * sinRot;
      double rotBy = bX * sinRot + bY * cosRot;
      double rotCx = cX * cosRot - cY * sinRot;
      double rotCy = cX * sinRot + cY * cosRot;

      // Absolute positions
      final aAbsX = tri.centerX + rotAx;
      final aAbsY = tri.centerY + rotAy;
      final bAbsX = tri.centerX + rotBx;
      final bAbsY = tri.centerY + rotBy;
      final cAbsX = tri.centerX + rotCx;
      final cAbsY = tri.centerY + rotCy;

      // Setup path
      _trianglePath.reset();
      _trianglePath.moveTo(aAbsX, aAbsY);
      _trianglePath.lineTo(bAbsX, bAbsY);
      _trianglePath.lineTo(cAbsX, cAbsY);
      _trianglePath.close();

      // 1. Dark translucent backdrop panel
      _backdropPaint.color = const Color(0xCC090C14);
      canvas.drawPath(_trianglePath, _backdropPaint);

      // 2. Render Stroke Boundary
      _strokePaint.strokeWidth = tri.strokeWidth;
      _strokePaint.color = const Color(0xAAFFFFFF);
      canvas.drawPath(_trianglePath, _strokePaint);

      // Ensure puck position is valid (fallback to centroid if unset)
      if (tri.puckX == 0.0 && tri.puckY == 0.0) {
        tri.puckX = tri.weightA * aAbsX + tri.weightB * bAbsX + tri.weightC * cAbsX;
        tri.puckY = tri.weightA * aAbsY + tri.weightB * bAbsY + tri.weightC * cAbsY;
      }

      // 3. Subtle guide lines connecting vertices to puck
      _guidePaint.color = Color(tri.cornerAColorHex.toInt()).withValues(alpha: 0.35);
      canvas.drawLine(Offset(aAbsX, aAbsY), Offset(tri.puckX, tri.puckY), _guidePaint);
      _guidePaint.color = Color(tri.cornerBColorHex.toInt()).withValues(alpha: 0.35);
      canvas.drawLine(Offset(bAbsX, bAbsY), Offset(tri.puckX, tri.puckY), _guidePaint);
      _guidePaint.color = Color(tri.cornerCColorHex.toInt()).withValues(alpha: 0.35);
      canvas.drawLine(Offset(cAbsX, cAbsY), Offset(tri.puckX, tri.puckY), _guidePaint);

      // 4. Render Corner Vertex Dots
      _cornerPaint.color = Color(tri.cornerAColorHex.toInt());
      canvas.drawCircle(Offset(aAbsX, aAbsY), 6.0, _cornerPaint);
      _cornerPaint.color = Color(tri.cornerBColorHex.toInt());
      canvas.drawCircle(Offset(bAbsX, bAbsY), 6.0, _cornerPaint);
      _cornerPaint.color = Color(tri.cornerCColorHex.toInt());
      canvas.drawCircle(Offset(cAbsX, cAbsY), 6.0, _cornerPaint);

      // 5. Render Selected Dot Marker (Puck)
      // Glow / Aura
      final double auraRadius = tri.isDragging > 0.0 ? 16.0 : 12.0;
      final double auraAlpha = tri.isDragging > 0.0 ? 0.55 : 0.30;
      _auraPaint.color = Color(tri.puckColorHex.toInt()).withValues(alpha: auraAlpha);
      canvas.drawCircle(Offset(tri.puckX, tri.puckY), auraRadius, _auraPaint);

      // Outer crisp ring
      _ringPaint.color = const Color(0xFFFFFFFF);
      canvas.drawCircle(Offset(tri.puckX, tri.puckY), 9.0, _ringPaint);

      // Inner selected dot core
      _puckPaint.color = Color(tri.puckColorHex.toInt());
      canvas.drawCircle(Offset(tri.puckX, tri.puckY), 5.5, _puckPaint);

      // 6. Corner Labels with Percentages
      _renderLabel(canvas, 'BUILD ${(tri.weightA * 100).round()}%', aAbsX, aAbsY - 20.0,
          Color(tri.cornerAColorHex.toInt()));
      _renderLabel(canvas, 'HEAT ${(tri.weightB * 100).round()}%', bAbsX + 15.0, bAbsY + 8.0,
          Color(tri.cornerBColorHex.toInt()));
      _renderLabel(canvas, 'GATHER ${(tri.weightC * 100).round()}%', cAbsX - 15.0, cAbsY + 8.0,
          Color(tri.cornerCColorHex.toInt()));
    }
  }

  void _renderLabel(Canvas canvas, String text, double cx, double cy, Color color) {
    final builder = ParagraphBuilder(ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 11.0,
      fontWeight: FontWeight.bold,
    ))
      ..pushStyle(TextStyle(color: color))
      ..addText(text);
    final p = builder.build()..layout(const ParagraphConstraints(width: 120.0));
    canvas.drawParagraph(p, Offset(cx - 60.0, cy));
  }
}
