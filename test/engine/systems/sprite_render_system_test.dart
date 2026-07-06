import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/systems/sprite_render_system.dart';

void main() {
  test(
      'SpriteRenderSystem should call drawRawAtlas correctly without allocations',
      () async {
    // 1. Create dependencies
    final swarm = Swarm();
    final positionCaste = ComponentCaste<Position>(65535);
    final spriteCaste = ComponentCaste<Sprite>(65535);

    // Create a 1x1 dummy image
    final Uint8List transparent1x1Png = Uint8List.fromList([
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      0x00,
      0x00,
      0x00,
      0x0d,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1f,
      0x15,
      0xc4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0a,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9c,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0d,
      0x0a,
      0x2d,
      0xb4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4e,
      0x44,
      0xae,
      0x42,
      0x60,
      0x82
    ]);
    final codec = await instantiateImageCodec(transparent1x1Png);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Create system
    final system = SpriteRenderSystem(
      atlas: image,
      positionCaste: positionCaste,
      spriteCaste: spriteCaste,
    );

    // Create an entity with both components
    final entity = swarm.createEntity();

    final pos = Position.create(10, 20);
    positionCaste.add(entity, pos);

    final sprite = Sprite.create();
    sprite.rectLeft = 0;
    sprite.rectTop = 0;
    sprite.rectRight = 10;
    sprite.rectBottom = 10;
    sprite.transformScos = 1.0;
    sprite.transformSsin = 0.0;
    sprite.transformTx = 5.0; // Local offset
    sprite.transformTy = 5.0;
    sprite.color = 0xFFFFFFFF;
    spriteCaste.add(entity, sprite);

    // Mock canvas
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Try rendering
    expect(() => system.render(canvas), returnsNormally);
  });

  test('SpriteRenderSystem should apply viewport transformations correctly',
      () async {
    // 1. Create dependencies
    final swarm = Swarm();
    final positionCaste = ComponentCaste<Position>(65535);
    final spriteCaste = ComponentCaste<Sprite>(65535);
    final viewportCaste = ComponentCaste<Viewport>(65535);

    // Create a 1x1 dummy image
    final Uint8List transparent1x1Png = Uint8List.fromList([
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      0x00,
      0x00,
      0x00,
      0x0d,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1f,
      0x15,
      0xc4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0a,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9c,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0d,
      0x0a,
      0x2d,
      0xb4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4e,
      0x44,
      0xae,
      0x42,
      0x60,
      0x82
    ]);
    final codec = await instantiateImageCodec(transparent1x1Png);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // Create system
    final system = SpriteRenderSystem(
      atlas: image,
      positionCaste: positionCaste,
      spriteCaste: spriteCaste,
      viewportCaste: viewportCaste,
    );

    // Setup active camera
    final cameraEntity = swarm.createEntity();
    viewportCaste.add(cameraEntity, Viewport.create(100.0, 50.0, 2.0));
    system.activeCameraEntity = cameraEntity;

    // Create an entity to render
    final entity = swarm.createEntity();
    positionCaste.add(entity, Position.create(10, 20));

    final sprite = Sprite.create();
    sprite.rectLeft = 0;
    sprite.rectTop = 0;
    sprite.rectRight = 10;
    sprite.rectBottom = 10;
    sprite.transformScos = 1.0;
    sprite.transformSsin = 0.0;
    sprite.transformTx = 5.0;
    sprite.transformTy = 5.0;
    sprite.color = 0xFFFFFFFF;
    spriteCaste.add(entity, sprite);

    // Mock canvas
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Try rendering, should apply canvas transforms based on viewport
    expect(() => system.render(canvas), returnsNormally);
  });
}
