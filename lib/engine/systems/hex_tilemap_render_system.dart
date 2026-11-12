import 'dart:ui';
import 'dart:typed_data';
import '../ecs/query.dart';
import '../ecs/component_storage.dart';
import '../components/position.dart';
import '../components/hex_tilemap.dart';
import '../components/viewport.dart';
import '../components/shader_material.dart';
import '../math/hex_math.dart';

/// Renders hexagonal tilemaps ([HexTilemap]) using batched drawing via [Canvas.drawRawAtlas].
///
/// Converts axial coordinates into Cartesian coordinates using [HexMath] and batches draw calls.
/// Ensures zero per-frame heap allocations with pre-allocated buffers.
class HexTilemapRenderSystem {
  /// The shared texture atlas containing hexagonal tile sprites.
  final Image atlas;

  /// Query for entities having both [Position] and [HexTilemap].
  final Query2<Position, HexTilemap> query;

  /// Optional storage for camera viewports.
  final ComponentStorage<Viewport>? viewportCaste;

  /// Optional storage for per-entity shader materials.
  final ComponentStorage<ShaderMaterial>? shaderCaste;

  /// Entity ID of the active camera, or -1 if no camera is active.
  int activeCameraEntity;

  /// Horizontal offset into the atlas image in pixels.
  double atlasOffsetX;

  /// Vertical offset into the atlas image in pixels.
  double atlasOffsetY;

  /// The outer radius (distance from center to corner) of each hexagonal tile.
  final double hexSize;

  final Float32List _transforms;
  final Float32List _rects;
  final Paint _paint;

  /// Creates a new [HexTilemapRenderSystem].
  HexTilemapRenderSystem({
    required this.atlas,
    required ComponentStorage<Position> positionCaste,
    required ComponentStorage<HexTilemap> hexTilemapCaste,
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

  /// Renders all hexagonal tilemaps to the [canvas] at the specified subpixel [scale].
  void render(Canvas canvas, [double scale = 1.0]) {
    _paint.shader = null;
    int totalTilesDrawn = 0;

    final hasViewport =
        Viewport.applyCamera(canvas, activeCameraEntity, viewportCaste, scale);

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
      final double startX = Viewport.snapToPixel(position.x, scale);
      final double startY = Viewport.snapToPixel(position.y, scale);

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
          _transforms[transformIndex + 2] =
              startX + hexX - (tileWidth / 2.0); // tx
          _transforms[transformIndex + 3] =
              startY + hexY - (tileHeight / 2.0); // ty

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
