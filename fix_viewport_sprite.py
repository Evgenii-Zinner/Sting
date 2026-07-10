with open('lib/engine/systems/sprite_render_system.dart', 'r') as f:
    content = f.read()

old_flush = """    void flushBatch(int countToFlush) {
      if (countToFlush == 0) return;

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

      canvas.drawRawAtlas(
        atlas,
        Float32List.sublistView(_transforms, 0, countToFlush * 4),
        Float32List.sublistView(_rects, 0, countToFlush * 4),
        Int32List.sublistView(_colors, 0, countToFlush),
        BlendMode.modulate,
        null, // cullRect
        _paint,
      );

      if (hasViewport) {
        canvas.restore();
      }
    }"""

new_flush = """    void flushBatch(int countToFlush) {
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
    }"""

content = content.replace(old_flush, new_flush)

old_start = """  void render(Canvas canvas, [double scale = 1.0]) {
    _paint.shader = null;
    int count = 0;"""

new_start = """  void render(Canvas canvas, [double scale = 1.0]) {
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
    }"""

content = content.replace(old_start, new_start)

old_end = """    if (count > 0) {
      flushBatch(count);
    }
  }"""

new_end = """    if (count > 0) {
      flushBatch(count);
    }

    if (hasViewport) {
      canvas.restore();
    }
  }"""

content = content.replace(old_end, new_end)

with open('lib/engine/systems/sprite_render_system.dart', 'w') as f:
    f.write(content)
