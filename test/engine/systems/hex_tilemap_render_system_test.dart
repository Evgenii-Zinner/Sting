import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/hex_tilemap.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/systems/hex_tilemap_render_system.dart';

void main() {
  test('HexTilemapRenderSystem should call drawRawAtlas correctly without allocations', () async {
    final swarm = Swarm();
    final positionCaste = ComponentCaste<Position>(65535);
    final tilemapCaste = ComponentCaste<HexTilemap>(65535);

    // Create a dummy image
    final Uint8List transparent1x1Png = Uint8List.fromList([
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4,
      0x89, 0x00, 0x00, 0x00, 0x0a, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae,
      0x42, 0x60, 0x82
    ]);
    final codec = await instantiateImageCodec(transparent1x1Png);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final system = HexTilemapRenderSystem(
      atlas: image,
      positionCaste: positionCaste,
      hexTilemapCaste: tilemapCaste,
      hexSize: 16.0,
    );

    final entity = swarm.createEntity();
    positionCaste.add(entity, Position.create(10, 20));

    final tilemap = HexTilemap.create(1, 0); // Pointy topped
    tilemap.setTile(0, 0, 1);
    tilemap.setTile(1, 0, 1);
    tilemapCaste.add(entity, tilemap);

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    expect(() => system.render(canvas), returnsNormally);
  });
}
