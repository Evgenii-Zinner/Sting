import 'dart:ui';
import 'dart:math' as math;
import 'dart:typed_data';
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

  // 1D Shadow Map components
  late final Float32List _depthBuffer;
  late final Float32List _rayCos;
  late final Float32List _raySin;
  late final double _invTwoPiRayCount;
  static const double _twoPi = math.pi * 2.0;

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
        _shadowPath = Path() {
    _depthBuffer = Float32List(rayCount);
    _rayCos = Float32List(rayCount);
    _raySin = Float32List(rayCount);
    _invTwoPiRayCount = rayCount / _twoPi;

    for (int i = 0; i < rayCount; i++) {
      final double angle = i * _twoPi / rayCount;
      _rayCos[i] = math.cos(angle);
      _raySin[i] = math.sin(angle);
    }
  }

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

      // 2. Fast 1D shadow mapping via edge rasterization
      for (int i = 0; i < rayCount; i++) {
        _depthBuffer[i] = radius;
      }

      for (int j = 0; j < _potentialCasters.length; j++) {
        final int targetEntity = _potentialCasters[j];
        final targetPos = _positionCaste.get(targetEntity)!;
        final targetBounds = _boundingBoxCaste.get(targetEntity)!;

        // Bounding box edges relative to the light center
        final double left = targetPos.x - lx;
        final double right = left + targetBounds.width;
        final double top = targetPos.y - ly;
        final double bottom = top + targetBounds.height;

        _rasterizeEdge(left, top, right, top);       // Top edge
        _rasterizeEdge(right, top, right, bottom);    // Right edge
        _rasterizeEdge(right, bottom, left, bottom);  // Bottom edge
        _rasterizeEdge(left, bottom, left, top);      // Left edge
      }

      for (int i = 0; i < rayCount; i++) {
        final double dist = _depthBuffer[i];
        final double endX = lx + _rayCos[i] * dist;
        final double endY = ly + _raySin[i] * dist;

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

  // Rasterizes a line segment relative to the light center into the 1D shadow map
  void _rasterizeEdge(double ax, double ay, double bx, double by) {
    double thetaA = math.atan2(ay, ax);
    double thetaB = math.atan2(by, bx);

    if (thetaA < 0) thetaA += _twoPi;
    if (thetaB < 0) thetaB += _twoPi;

    double diff = thetaB - thetaA;
    if (diff > math.pi) {
      diff -= _twoPi;
    } else if (diff < -math.pi) {
      diff += _twoPi;
    }

    double startAngle, endAngle;
    if (diff > 0) {
      startAngle = thetaA;
      endAngle = thetaA + diff;
    } else {
      startAngle = thetaB;
      endAngle = thetaB - diff;
    }

    int startBin = (startAngle * _invTwoPiRayCount).floor();
    int endBin = (endAngle * _invTwoPiRayCount).ceil();

    final double nx = by - ay;
    final double ny = -(bx - ax);
    final double c = ax * nx + ay * ny;

    for (int i = startBin; i <= endBin; i++) {
      int bin = i % rayCount;
      if (bin < 0) bin += rayCount;

      final double denom = _rayCos[bin] * nx + _raySin[bin] * ny;
      if (denom != 0.0) {
        final double t = c / denom;
        if (t > 0.0 && t < _depthBuffer[bin]) {
          _depthBuffer[bin] = t;
        }
      }
    }
  }
}
