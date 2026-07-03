import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/systems/movement_system.dart';
import 'package:sting/engine/systems/sprite_render_system.dart';

class MockCanvas extends Fake implements Canvas {
  bool drawRawAtlasCalled = false;

  @override
  void drawRawAtlas(Image atlas, Float32List rstTransforms, Float32List rects, Int32List? colors, BlendMode? blendMode, Rect? cullRect, Paint paint) {
    drawRawAtlasCalled = true;
  }
}

void main() {
  test('ECS Integration: Update logic and render pipeline', () async {
    final swarm = Swarm();
    final positionCaste = ComponentCaste<Position>(65535);
    final velocityCaste = ComponentCaste<Velocity>(65535);
    final spriteCaste = ComponentCaste<Sprite>(65535);

    // Create a dummy image
    final Uint8List transparent1x1Png = Uint8List.fromList([
      0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
      0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89,
      0x00, 0x00, 0x00, 0x0a, 0x49, 0x44, 0x41, 0x54,
      0x78, 0x9c, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0d, 0x0a, 0x2d, 0xb4,
      0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82
    ]);
    final codec = await instantiateImageCodec(transparent1x1Png);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final movementSystem = MovementSystem(
      positionCaste: positionCaste,
      velocityCaste: velocityCaste,
    );
    final renderSystem = SpriteRenderSystem(
      atlas: image,
      positionCaste: positionCaste,
      spriteCaste: spriteCaste,
    );

    // Create entity with Position, Velocity, and Sprite
    final entity = swarm.createEntity();
    positionCaste.add(entity, Position.create(10, 20));
    velocityCaste.add(entity, Velocity.create(5, 5));

    final sprite = Sprite.create();
    sprite.rectLeft = 0;
    sprite.rectTop = 0;
    sprite.rectRight = 10;
    sprite.rectBottom = 10;
    sprite.transformScos = 1.0;
    sprite.transformSsin = 0.0;
    sprite.transformTx = 0.0;
    sprite.transformTy = 0.0;
    sprite.color = 0xFFFFFFFF;
    spriteCaste.add(entity, sprite);

    // Tick the logic
    movementSystem.update(1.0); // dt = 1.0

    // Verify logic updated state
    final pos = positionCaste.get(entity)!;
    expect(pos.x, 15.0);
    expect(pos.y, 25.0);

    // Mock Canvas and render
    final mockCanvas = MockCanvas();
    renderSystem.render(mockCanvas);

    // Verify render was called
    expect(mockCanvas.drawRawAtlasCalled, isTrue);
  });
}
