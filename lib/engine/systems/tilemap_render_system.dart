import 'dart:ui';
import 'dart:typed_data';
import '../ecs/query.dart';
import '../ecs/component_caste.dart';
import '../components/position.dart';
import '../components/tilemap.dart';
import '../components/viewport.dart';
import '../components/shader_material.dart';

class TilemapRenderSystem {
  final Image atlas;
  final Query2<Position, Tilemap> query;
  final ComponentCaste<Viewport>? viewportCaste;
  final ComponentCaste<ShaderMaterial>? shaderCaste;
  int activeCameraEntity;

  double atlasOffsetX;
  double atlasOffsetY;

  // Pre-allocated arrays for drawAtlas to prevent per-frame allocations.
  // Using maximum capacities. In a real scenario we'd bound this by a reasonable max tiles.
  // 4 floats per transform, 4 floats per rect
  // For tilemaps, the number of tiles can be large, so we size these arrays to handle
  // the max tiles we expect to render at once. Let's assume a reasonable max like 10,000 tiles per render pass.
  // Or we can pre-allocate dynamically based on the constructor.
  final Float32List _transforms;
  final Float32List _rects;
  final Paint _paint;

  // No colors array, we'll draw without tinting.

  TilemapRenderSystem({
    required this.atlas,
    required ComponentCaste<Position> positionCaste,
    required ComponentCaste<Tilemap> tilemapCaste,
    this.viewportCaste,
    this.shaderCaste,
    this.activeCameraEntity = -1,
    this.atlasOffsetX = 0.0,
    this.atlasOffsetY = 0.0,
    int maxTiles = 65535, // Adjust this based on max expected visible tiles
  })  : query = Query2<Position, Tilemap>(positionCaste, tilemapCaste),
        _transforms = Float32List(maxTiles * 4),
        _rects = Float32List(maxTiles * 4),
        _paint = Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false;

  void render(Canvas canvas, [double scale = 1.0]) {
    _paint.shader = null;
    int totalTilesDrawn = 0;

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

    void flushBatch(int tilesToFlush) {
      if (tilesToFlush == 0) return;

      canvas.drawRawAtlas(
        atlas,
        Float32List.sublistView(_transforms, 0, tilesToFlush * 4),
        Float32List.sublistView(_rects, 0, tilesToFlush * 4),
        null, // No colors array
        BlendMode.srcOver, // Use srcOver when not modulating with colors
        null, // cullRect
        _paint,
      );
    }

    query.forEach((entity, position, tilemap) {
      final material = shaderCaste?.get(entity);

      if (material != currentMaterial || material?.shader != currentShader) {
        if (totalTilesDrawn > 0) {
          flushBatch(totalTilesDrawn);
          totalTilesDrawn = 0;
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

      final atlasWidth = atlas.width;
      final tilesPerRow = atlasWidth ~/ tilemap.tileWidth;

      // Snap start position to physical pixel grid
      final double startX = (position.x * scale).roundToDouble() / scale;
      final double startY = (position.y * scale).roundToDouble() / scale;

      outer:
      for (int row = 0; row < tilemap.rows; row++) {
        for (int col = 0; col < tilemap.columns; col++) {
          final tileId = tilemap.getTile(col, row);

          if (tileId <= 0) continue; // Skip empty tiles (assuming 0 is empty)

          if (totalTilesDrawn * 4 >= _transforms.length) {
            // Prevent out-of-bounds if we exceed pre-allocated space
            break outer;
          }

          // Calculate destination transform (Translation only, scos=1, ssin=0)
          final transformIndex = totalTilesDrawn * 4;
          _transforms[transformIndex] = 1.0; // scos
          _transforms[transformIndex + 1] = 0.0; // ssin
          _transforms[transformIndex + 2] =
              startX + (col * tilemap.tileWidth); // tx
          _transforms[transformIndex + 3] =
              startY + (row * tilemap.tileHeight); // ty

          // Calculate source rect
          // Assuming tileId 1 is the first tile at (0,0) in atlas
          final atlasIndex = tileId - 1;
          final atlasRow = atlasIndex ~/ tilesPerRow;
          final atlasCol = atlasIndex % tilesPerRow;

          final rectIndex = totalTilesDrawn * 4;
          final rectLeft =
              atlasOffsetX + (atlasCol * tilemap.tileWidth).toDouble();
          final rectTop =
              atlasOffsetY + (atlasRow * tilemap.tileHeight).toDouble();
          _rects[rectIndex] = rectLeft;
          _rects[rectIndex + 1] = rectTop;
          _rects[rectIndex + 2] = rectLeft + tilemap.tileWidth;
          _rects[rectIndex + 3] = rectTop + tilemap.tileHeight;

          totalTilesDrawn++;
        }
      }
    });

    if (totalTilesDrawn > 0) {
      flushBatch(totalTilesDrawn);
    }

    if (hasViewport) {
      canvas.restore();
    }
  }
}
