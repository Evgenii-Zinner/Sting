import 'dart:ui';
import 'dart:typed_data';
import '../ecs/query.dart';
import '../ecs/component_caste.dart';
import '../components/position.dart';
import '../components/sprite.dart';
import '../components/viewport.dart';

class SpriteRenderSystem {
  final Image atlas;
  final Query2<Position, Sprite> query;
  final ComponentCaste<Viewport>? viewportCaste;
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
    this.activeCameraEntity = -1,
    int maxEntities = 65535,
  }) : query = Query2<Position, Sprite>(positionCaste, spriteCaste),
       _transforms = Float32List(maxEntities * 4),
       _rects = Float32List(maxEntities * 4),
       _colors = Int32List(maxEntities),
       _paint = Paint();

  void render(Canvas canvas) {
    int count = 0;

    query.forEach((entity, position, sprite) {
      // 1. Fill RSTransform (scos, ssin, tx, ty)
      final transformIndex = count * 4;
      _transforms[transformIndex] = sprite.transformScos;
      _transforms[transformIndex + 1] = sprite.transformSsin;
      // Position is applied as translation.  If sprite tx/ty is meant to be local offset,
      // it should be added here.
      _transforms[transformIndex + 2] = position.x + sprite.transformTx;
      _transforms[transformIndex + 3] = position.y + sprite.transformTy;

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

    if (count == 0) return;

    bool hasViewport = false;
    if (activeCameraEntity != -1 && viewportCaste != null) {
      final viewport = viewportCaste!.get(activeCameraEntity);
      if (viewport != null) {
        hasViewport = true;
        canvas.save();
        canvas.scale(viewport.zoom, viewport.zoom);
        canvas.translate(-viewport.x, -viewport.y);
      }
    }

    // Use Canvas.drawRawAtlas to avoid object allocation.
    // drawRawAtlas uses flat Float32List and Int32List.
    // We must pass an empty Int32List for colors if we don't want tinting, but here we provide it.
    // However, the signature might differ slightly depending on dart:ui version.

    canvas.drawRawAtlas(
      atlas,
      // Pass sublists to avoid drawing garbage at the end
      Float32List.sublistView(_transforms, 0, count * 4),
      Float32List.sublistView(_rects, 0, count * 4),
      Int32List.sublistView(_colors, 0, count),
      BlendMode.modulate,
      null, // cullRect
      _paint,
    );

    if (hasViewport) {
      canvas.restore();
    }
  }
}
