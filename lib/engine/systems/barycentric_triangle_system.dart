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
  final Path _trianglePath;

  BarycentricTriangleSystem(this._triangles)
      : _strokePaint = Paint()..style = PaintingStyle.stroke,
        _puckPaint = Paint()..style = PaintingStyle.fill,
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
    final det = (bAbsY - cAbsY) * (aAbsX - cAbsX) + (cAbsX - bAbsX) * (aAbsY - cAbsY);
    
    double wA = ((bAbsY - cAbsY) * (px - cAbsX) + (cAbsX - bAbsX) * (py - cAbsY)) / det;
    double wB = ((cAbsY - aAbsY) * (px - cAbsX) + (aAbsX - cAbsX) * (py - cAbsY)) / det;
    double wC = 1.0 - wA - wB;

    // Clamping logic to equilateral boundary
    if (wA < 0.0 && wB < 0.0) {
        wC = 1.0; wA = 0.0; wB = 0.0;
    } else if (wB < 0.0 && wC < 0.0) {
        wA = 1.0; wB = 0.0; wC = 0.0;
    } else if (wC < 0.0 && wA < 0.0) {
        wB = 1.0; wC = 0.0; wA = 0.0;
    } else if (wA < 0.0) {
      wA = 0.0;
      final bcX = cAbsX - bAbsX;
      final bcY = cAbsY - bAbsY;
      final t = ((px - bAbsX) * bcX + (py - bAbsY) * bcY) / (bcX * bcX + bcY * bcY);
      final tClamped = max(0.0, min(1.0, t));
      wC = tClamped;
      wB = 1.0 - wC;
    } else if (wB < 0.0) {
      wB = 0.0;
      final caX = aAbsX - cAbsX;
      final caY = aAbsY - cAbsY;
      final t = ((px - cAbsX) * caX + (py - cAbsY) * caY) / (caX * caX + caY * caY);
      final tClamped = max(0.0, min(1.0, t));
      wA = tClamped;
      wC = 1.0 - tClamped;
    } else if (wC < 0.0) {
      wC = 0.0;
      final abX = bAbsX - aAbsX;
      final abY = bAbsY - aAbsY;
      final t = ((px - aAbsX) * abX + (py - aAbsY) * abY) / (abX * abX + abY * abY);
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

      // Render Stroke/Fill
      _strokePaint.strokeWidth = tri.strokeWidth;
      
      // Basic flat style rendering, gradient logic could be added using shaders if needed, 
      // but sticking to stroke for zero allocation for now
      _strokePaint.color = const Color(0xFFFFFFFF); // White for boundary
      canvas.drawPath(_trianglePath, _strokePaint);

      // Render Puck
      _puckPaint.color = Color(tri.puckColorHex.toInt());
      canvas.drawCircle(Offset(tri.puckX, tri.puckY), 8.0, _puckPaint); // 8.0 radius puck
    }
  }
}
