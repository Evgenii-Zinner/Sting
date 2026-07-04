import 'dart:ui';
import 'dart:math' as math;
import '../ecs/query.dart';
import '../ecs/component_caste.dart';
import '../components/position.dart';
import '../components/light.dart';
import '../components/bounding_box.dart';
import '../components/shadow_caster.dart';
import '../components/viewport.dart';
import 'spatial_hash_grid.dart';

class LightRenderSystem {
  final Query2<Position, Light> _lightQuery;
  final ComponentCaste<Position> _positionCaste;
  final ComponentCaste<BoundingBox> _boundingBoxCaste;
  final ComponentCaste<ShadowCaster> _shadowCasterCaste;
  final ComponentCaste<Viewport>? viewportCaste;

  SpatialHashGrid? spatialHashGrid;
  int activeCameraEntity;

  // Ambient light settings
  Color ambientColor;
  bool renderAmbient;

  // Pre-allocated objects to prevent per-frame allocations
  final Paint _lightPaint;
  final Paint _ambientPaint;
  final Path _shadowPath;

  // Number of rays to cast for shadow polygon (resolution of the light)
  final int rayCount;

  // Pre-allocated array to store shadow casters in range of the current light
  final List<int> _potentialCasters = [];

  LightRenderSystem({
    required ComponentCaste<Position> positionCaste,
    required ComponentCaste<Light> lightCaste,
    required ComponentCaste<BoundingBox> boundingBoxCaste,
    required ComponentCaste<ShadowCaster> shadowCasterCaste,
    this.viewportCaste,
    this.spatialHashGrid,
    this.activeCameraEntity = -1,
    this.ambientColor = const Color(0xB3000000), // 70% black
    this.renderAmbient = true,
    this.rayCount = 128,
  })  : _lightQuery = Query2<Position, Light>(positionCaste, lightCaste),
        _positionCaste = positionCaste,
        _boundingBoxCaste = boundingBoxCaste,
        _shadowCasterCaste = shadowCasterCaste,
        _lightPaint = Paint()
          ..blendMode = BlendMode.plus
          ..isAntiAlias = false,
        _ambientPaint = Paint()
          ..blendMode = BlendMode.srcOver
          ..isAntiAlias = false,
        _shadowPath = Path();

  void render(Canvas canvas, Size size, [double scale = 1.0]) {
    double offsetX = 0.0;
    double offsetY = 0.0;
    double zoom = 1.0;

    bool hasViewport = false;
    if (activeCameraEntity != -1 && viewportCaste != null) {
      final viewport = viewportCaste!.get(activeCameraEntity);
      if (viewport != null) {
        hasViewport = true;
        zoom = viewport.zoom;
        offsetX = (viewport.x * scale).roundToDouble() / scale;
        offsetY = (viewport.y * scale).roundToDouble() / scale;

        canvas.save();
        canvas.scale(zoom, zoom);
        canvas.translate(-offsetX, -offsetY);
      }
    }

    if (renderAmbient) {
      // Need to cover the whole screen, considering viewport transform
      _ambientPaint.color = ambientColor;
      if (hasViewport) {
        final screenRect = Rect.fromLTWH(
          offsetX,
          offsetY,
          size.width / zoom,
          size.height / zoom
        );
        canvas.drawRect(screenRect, _ambientPaint);
      } else {
        canvas.drawRect(Offset.zero & size, _ambientPaint);
      }
    }

    _lightQuery.forEach((entity, position, light) {
      if (!light.active) return;

      final double lx = position.x;
      final double ly = position.y;
      final double radius = light.radius;

      // Skip rendering if light is outside the visible screen area
      if (hasViewport) {
        final double screenLeft = offsetX;
        final double screenTop = offsetY;
        final double screenRight = offsetX + size.width / zoom;
        final double screenBottom = offsetY + size.height / zoom;

        if (lx + radius < screenLeft ||
            lx - radius > screenRight ||
            ly + radius < screenTop ||
            ly - radius > screenBottom) {
          return;
        }
      }

      // 1. Broad phase query to find all potential shadow casters once per light
      int casterCount = 0;
      // Use the entity ID as an index or just a temporary list.
      // To strictly adhere to zero per-frame allocations, we can use a class-level list
      // and clear it. But since we need a list anyway, let's declare it at the class level.
      // See below for adding _potentialCasters to the class.
      _potentialCasters.clear();

      if (spatialHashGrid != null) {
        spatialHashGrid!.queryAABB(lx - radius, ly - radius, radius * 2, radius * 2, (targetEntity) {
           if (targetEntity == entity) return true; // Don't shadow self

           final shadowCaster = _shadowCasterCaste.get(targetEntity);
           if (shadowCaster == null || !shadowCaster.active) return true;

           final targetPos = _positionCaste.get(targetEntity);
           final targetBounds = _boundingBoxCaste.get(targetEntity);

           if (targetPos != null && targetBounds != null) {
              _potentialCasters.add(targetEntity);
           }
           return true;
        });
      } else {
        // Fallback O(N) if no spatial hash grid is provided
        for(int j=0; j<_shadowCasterCaste.length; j++) {
          final shadowCaster = _shadowCasterCaste.getComponentAt(j);
          if (shadowCaster == null || !shadowCaster.active) continue;

          final targetEntity = _shadowCasterCaste.elementAt(j);
          if (targetEntity == entity) continue;

          final targetPos = _positionCaste.get(targetEntity);
          final targetBounds = _boundingBoxCaste.get(targetEntity);

          if (targetPos != null && targetBounds != null) {
            _potentialCasters.add(targetEntity);
          }
        }
      }

      _shadowPath.reset();

      // 2. Simple 1D shadow mapping via raycasting
      final double angleStep = (math.pi * 2.0) / rayCount;

      for (int i = 0; i < rayCount; i++) {
        final double angle = i * angleStep;
        final double dx = math.cos(angle);
        final double dy = math.sin(angle);

        double minDistance = radius;

        // Check against the pre-filtered potential casters
        for (int j = 0; j < _potentialCasters.length; j++) {
          final int targetEntity = _potentialCasters[j];
          final targetPos = _positionCaste.get(targetEntity)!;
          final targetBounds = _boundingBoxCaste.get(targetEntity)!;

          final double left = targetPos.x;
          final double right = left + targetBounds.width;
          final double top = targetPos.y;
          final double bottom = top + targetBounds.height;

          final double dist = _rayIntersectAABB(lx, ly, dx, dy, left, top, right, bottom);
          if (dist > 0 && dist < minDistance) {
             minDistance = dist;
          }
        }

        final double endX = lx + dx * minDistance;
        final double endY = ly + dy * minDistance;

        if (i == 0) {
          _shadowPath.moveTo(endX, endY);
        } else {
          _shadowPath.lineTo(endX, endY);
        }
      }

      _shadowPath.close();

      // Draw the light gradient
      final int alpha = (light.intensity * 255).toInt().clamp(0, 255);
      final int r = (light.r * 255).toInt().clamp(0, 255);
      final int g = (light.g * 255).toInt().clamp(0, 255);
      final int b = (light.b * 255).toInt().clamp(0, 255);

      _lightPaint.shader = Gradient.radial(
        Offset(lx, ly),
        radius,
        [
          Color.fromARGB(alpha, r, g, b),
          Color.fromARGB(0, r, g, b),
        ],
      );

      canvas.drawPath(_shadowPath, _lightPaint);
    });

    if (hasViewport) {
      canvas.restore();
    }
  }

  // Fast Ray vs AABB intersection returning distance, or -1 if no intersection
  double _rayIntersectAABB(double rx, double ry, double rdx, double rdy, double minX, double minY, double maxX, double maxY) {
      double tmin = -double.infinity;
      double tmax = double.infinity;

      if (rdx != 0.0) {
        double tx1 = (minX - rx) / rdx;
        double tx2 = (maxX - rx) / rdx;
        tmin = math.max(tmin, math.min(tx1, tx2));
        tmax = math.min(tmax, math.max(tx1, tx2));
      } else if (rx < minX || rx > maxX) {
        return -1.0;
      }

      if (rdy != 0.0) {
        double ty1 = (minY - ry) / rdy;
        double ty2 = (maxY - ry) / rdy;
        tmin = math.max(tmin, math.min(ty1, ty2));
        tmax = math.min(tmax, math.max(ty1, ty2));
      } else if (ry < minY || ry > maxY) {
        return -1.0;
      }

      if (tmax >= tmin && tmax >= 0.0) {
         return tmin > 0.0 ? tmin : tmax;
      }
      return -1.0;
  }
}
