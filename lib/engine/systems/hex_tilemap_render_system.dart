import 'dart:ui';
import 'dart:typed_data';
import '../ecs/query.dart';
import '../ecs/component_caste.dart';
import '../components/position.dart';
import '../components/hex_tilemap.dart';
import '../components/viewport.dart';
import '../components/shader_material.dart';
import '../math/hex_math.dart';

class HexTilemapRenderSystem {
  final Image atlas;
  final Query2<Position, HexTilemap> query;
  final ComponentCaste<Viewport>? viewportCaste;
  final ComponentCaste<ShaderMaterial>? shaderCaste;
  int activeCameraEntity;

  double atlasOffsetX;
  double atlasOffsetY;

  final double hexSize;

  // Pre-allocated arrays for drawAtlas to prevent per-frame allocations.
  final Float32List _transforms;
  final Float32List _rects;
  final Paint _paint;

  HexTilemapRenderSystem({
    required this.atlas,
    required ComponentCaste<Position> positionCaste,
    required ComponentCaste<HexTilemap> hexTilemapCaste,
    required this.hexSize,
    this.viewportCaste,
    this.shaderCaste,
    this.activeCameraEntity = -1,
    this.atlasOffsetX = 0.0,
    this.atlasOffsetY = 0.0,
    int maxTiles = 65535,
  })  : query = Query2<Position, HexTilemap>(positionCaste, hexTilemapCaste),
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

      // Hex map uses an atlas. Assuming the atlas contains a grid of hexagonal tile sprites.
      // We will assume the sprite width is the bounding box of the hexagon.
      // For pointy-topped: width = sqrt(3) * size, height = 2 * size
      // For flat-topped: width = 2 * size, height = sqrt(3) * size

      final double tileWidth = tilemap.isFlatTopped == 1
          ? 2.0 * hexSize
          : 1.7320508075688772 * hexSize; // sqrt(3) * hexSize

      final double tileHeight = tilemap.isFlatTopped == 1
          ? 1.7320508075688772 * hexSize
          : 2.0 * hexSize;

      final atlasWidth = atlas.width;
      final int intTileWidth = tileWidth.round();
      final int intTileHeight = tileHeight.round();
      final tilesPerRow = intTileWidth > 0 ? atlasWidth ~/ intTileWidth : 1;

      // Snap start position to physical pixel grid
      final double startX = (position.x * scale).roundToDouble() / scale;
      final double startY = (position.y * scale).roundToDouble() / scale;

      final int radius = tilemap.radius;

      outer:
      for (int r = -radius; r <= radius; r++) {
        for (int q = -radius; q <= radius; q++) {
          final tileId = tilemap.getTile(q, r);

          if (tileId <= 0) continue; // Skip empty tiles

          if (totalTilesDrawn * 4 >= _transforms.length) {
            break outer;
          }

          // Calculate destination transform (Translation only)
          final (hexX, hexY) = tilemap.isFlatTopped == 1
              ? HexMath.flatGridToWorld(q, r, hexSize)
              : HexMath.pointyGridToWorld(q, r, hexSize);

          final transformIndex = totalTilesDrawn * 4;
          _transforms[transformIndex] = 1.0; // scos
          _transforms[transformIndex + 1] = 0.0; // ssin

          // Center the tile sprite on the hex coordinate
          _transforms[transformIndex + 2] = startX + hexX - (tileWidth / 2.0); // tx
          _transforms[transformIndex + 3] = startY + hexY - (tileHeight / 2.0); // ty

          // Calculate source rect
          // Assuming tileId 1 is the first tile at (0,0) in atlas
          final atlasIndex = tileId - 1;
          final atlasRow = tilesPerRow > 0 ? atlasIndex ~/ tilesPerRow : 0;
          final atlasCol = tilesPerRow > 0 ? atlasIndex % tilesPerRow : 0;

          final rectIndex = totalTilesDrawn * 4;
          final rectLeft = atlasOffsetX + (atlasCol * intTileWidth).toDouble();
          final rectTop = atlasOffsetY + (atlasRow * intTileHeight).toDouble();

          _rects[rectIndex] = rectLeft;
          _rects[rectIndex + 1] = rectTop;
          _rects[rectIndex + 2] = rectLeft + intTileWidth.toDouble();
          _rects[rectIndex + 3] = rectTop + intTileHeight.toDouble();

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
