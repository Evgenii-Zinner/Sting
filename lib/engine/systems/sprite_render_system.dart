import 'dart:ui';
import 'dart:typed_data';
import '../ecs/query.dart';
import '../ecs/component_caste.dart';
import '../components/position.dart';
import '../components/sprite.dart';
import '../components/viewport.dart';
import '../components/shader_material.dart';

class SpriteRenderSystem {
  final Image atlas;
  final Query2<Position, Sprite> query;
  final ComponentCaste<Viewport>? viewportCaste;
  final ComponentCaste<ShaderMaterial>? shaderCaste;
  int activeCameraEntity;

  // Pre-allocated arrays for drawAtlas to prevent per-frame allocations.
  // We need Float32List for RSTransform (4 floats each) and Rect (4 floats each)
  // We need Int32List for Color (1 int each)
  final Float32List _transforms;
  final Float32List _rects;
  final Int32List _colors;
  final Paint _paint;

  SpriteRenderSystem({
    required this.atlas,
    required ComponentCaste<Position> positionCaste,
    required ComponentCaste<Sprite> spriteCaste,
    this.viewportCaste,
    this.shaderCaste,
    this.activeCameraEntity = -1,
    int maxEntities = 65535,
  })  : query = Query2<Position, Sprite>(positionCaste, spriteCaste),
        _transforms = Float32List(maxEntities * 4),
        _rects = Float32List(maxEntities * 4),
        _colors = Int32List(maxEntities),
        _paint = Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false;

  void render(Canvas canvas, [double scale = 1.0]) {
    _paint.shader = null;
    int count = 0;

    bool hasViewport = false;
    if (activeCameraEntity != -1 && viewportCaste != null) {
      final viewport = viewportCaste!.get(activeCameraEntity);
      if (viewport != null) {
        hasViewport = true;
        canvas.save();
        canvas.scale(viewport.zoom, viewport.zoom);
        final double snappedVx = (viewport.x * scale).roundToDouble() / scale;
        final double snappedVy = (viewport.y * scale).roundToDouble() / scale;
        canvas.translate(-snappedVx, -snappedVy);
      }
    }
    FragmentShader? currentShader;
    ShaderMaterial? currentMaterial;

    void flushBatch(int countToFlush) {
      if (countToFlush == 0) return;

      canvas.drawRawAtlas(
        atlas,
        Float32List.sublistView(_transforms, 0, countToFlush * 4),
        Float32List.sublistView(_rects, 0, countToFlush * 4),
        Int32List.sublistView(_colors, 0, countToFlush),
        BlendMode.modulate,
        null, // cullRect
        _paint,
      );
    }

    query.forEach((entity, position, sprite) {
      final material = shaderCaste?.get(entity);

      // We must flush the batch if the shader object changes OR if the material instance changes
      // (because a different material might have different uniform values even with the same shader)
      if (material != currentMaterial || material?.shader != currentShader) {
        if (count > 0) {
          flushBatch(count);
          count = 0;
        }
        currentShader = material?.shader;
        currentMaterial = material;
        _paint.shader = currentShader;

        if (material != null && currentShader != null) {
          for (int i = 0; i < material.uniforms.length; i++) {
            currentShader!.setFloat(i, material.uniforms[i]);
          }
        }
      }

      // 1. Fill RSTransform (scos, ssin, tx, ty)
      final transformIndex = count * 4;
      _transforms[transformIndex] = sprite.transformScos;
      _transforms[transformIndex + 1] = sprite.transformSsin;
      // Snap position to physical pixel grid to eliminate texture shimmering while allowing smooth sub-logical movement
      final double snappedX = (position.x * scale).roundToDouble() / scale;
      final double snappedY = (position.y * scale).roundToDouble() / scale;
      _transforms[transformIndex + 2] = snappedX + sprite.transformTx;
      _transforms[transformIndex + 3] = snappedY + sprite.transformTy;

      // 2. Fill Rect (left, top, right, bottom)
      final rectIndex = count * 4;
      _rects[rectIndex] = sprite.rectLeft;
      _rects[rectIndex + 1] = sprite.rectTop;
      _rects[rectIndex + 2] = sprite.rectRight;
      _rects[rectIndex + 3] = sprite.rectBottom;

      // 3. Fill Color
      _colors[count] = sprite.color;

      count++;
    });

    if (count > 0) {
      flushBatch(count);
    }

    if (hasViewport) {
      canvas.restore();
    }
  }
}
