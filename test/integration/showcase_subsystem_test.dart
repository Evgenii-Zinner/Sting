import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';

import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/scene.dart';

import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/hex_tilemap.dart';
import 'package:sting/engine/components/movement_queue.dart';
import 'package:sting/engine/components/utility_ai.dart';
import 'package:sting/engine/components/grid_diffusion.dart';
import 'package:sting/engine/components/shader_material.dart';

import 'package:sting/engine/systems/hex_tilemap_render_system.dart';
import 'package:sting/engine/systems/pathfinding_system.dart';
import 'package:sting/engine/systems/utility_ai_system.dart';
import 'package:sting/engine/systems/diffusion_system.dart';

class MockCanvas extends Fake implements Canvas {
  bool drawRawAtlasCalled = false;
  bool translateCalled = false;

  @override
  void drawRawAtlas(Image atlas, Float32List rstTransforms, Float32List rects,
      Int32List? colors, BlendMode? blendMode, Rect? cullRect, Paint paint) {
    drawRawAtlasCalled = true;
  }

  @override
  void translate(double dx, double dy) {
    translateCalled = true;
  }
}

void main() {
  test('Integration: Subsystem Interaction (Diffusion -> AI -> Pathfinding -> Shader)', () async {
    final scene = Scene();

    scene.registerCaste<Position>('Position', ComponentCaste<Position>(10));
    scene.registerCaste<HexTilemap>('HexTilemap', ComponentCaste<HexTilemap>(10));
    scene.registerCaste<MovementQueue>('MovementQueue', ComponentCaste<MovementQueue>(10));
    scene.registerCaste<UtilityAI>('UtilityAI', ComponentCaste<UtilityAI>(10));
    scene.registerCaste<GridDiffusion>('GridDiffusion', ComponentCaste<GridDiffusion>(10));
    scene.registerCaste<ShaderMaterial>('ShaderMaterial', ComponentCaste<ShaderMaterial>(10));

    final entity = scene.createEntity();

    // 1. Initial State Setup
    final gridDiffusion = GridDiffusion.create(columns: 5, rows: 5, diffusionRate: 0.25);
    gridDiffusion.setValueAt(12, 1.0); // Heat at center
    scene.getCaste<GridDiffusion>('GridDiffusion').add(entity, gridDiffusion);

    final utilityAi = UtilityAI.create(0, 0, 0, 0, 2);
    // Task 0: Stay idle (Base tension 0.1)
    utilityAi.tension[0] = 0.1; utilityAi.damping[0] = 0.0;
    // Task 1: Flee heat (Tension will be driven by diffusion)
    utilityAi.tension[1] = 0.0; utilityAi.damping[1] = 0.1;
    scene.getCaste<UtilityAI>('UtilityAI').add(entity, utilityAi);

    final movementQueue = MovementQueue.create(10);
    scene.getCaste<MovementQueue>('MovementQueue').add(entity, movementQueue);

    // ShaderMaterial with 1 uniform (heat intensity)
    final shaderMaterial = ShaderMaterial(null, 1);
    scene.getCaste<ShaderMaterial>('ShaderMaterial').add(entity, shaderMaterial);

    final hexTilemap = HexTilemap.create(2, 1);
    hexTilemap.setTile(0, 0, 1);
    scene.getCaste<HexTilemap>('HexTilemap').add(entity, hexTilemap);

    scene.getCaste<Position>('Position').add(entity, Position.create(0.0, 0.0));

    // 2. Diffusion Step
    final diffusionSystem = DiffusionSystem(diffusionCaste: scene.getCaste<GridDiffusion>('GridDiffusion'));
    diffusionSystem.update();

    final updatedGrid = scene.getCaste<GridDiffusion>('GridDiffusion').get(entity)!;
    final centerHeat = updatedGrid.getValueAt(12); // ~0.75 after diffusion
    expect(centerHeat, greaterThan(0.0));

    // 3. AI Step (Driven by Diffusion)
    final aiComp = scene.getCaste<UtilityAI>('UtilityAI').get(entity)!;
    // Inject heat directly into the "flee" task tension
    aiComp.tension[1] = centerHeat;

    final aiSystem = UtilityAISystem(scene);
    aiSystem.update(0.016);

    // Because tension[1] (0.75) > tension[0] (0.1), Task 1 should activate
    expect(aiComp.activeTaskId, 1);

    // 4. Pathfinding Step (Driven by AI)
    final pathfinder = GridPathfinder(25);
    final costGrid = Int32List(25)..fillRange(0, 25, 1);

    // If fleeing (Task 1), set path target to a corner (0). Else, stay at center (12).
    final targetNode = aiComp.activeTaskId == 1 ? 0 : 12;

    final found = pathfinder.findPath(
      12, // Start at center
      targetNode,
      costGrid,
      5,
      5,
      GridType.rectangular,
      scene.getCaste<MovementQueue>('MovementQueue').get(entity)!,
    );
    expect(found, isTrue);

    // 5. Shader/Render Step (Driven by State)
    final shaderComp = scene.getCaste<ShaderMaterial>('ShaderMaterial').get(entity)!;
    final queueComp = scene.getCaste<MovementQueue>('MovementQueue').get(entity)!;

    // Pass the path length to the shader as a uniform
    shaderComp.uniforms[0] = queueComp.count.toDouble();
    expect(shaderComp.uniforms[0], greaterThan(0));

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

    final renderSystem = HexTilemapRenderSystem(
      atlas: image,
      positionCaste: scene.getCaste<Position>('Position'),
      hexTilemapCaste: scene.getCaste<HexTilemap>('HexTilemap'),
      shaderCaste: scene.getCaste<ShaderMaterial>('ShaderMaterial'),
      hexSize: 10.0,
      maxTiles: 10,
    );

    final mockCanvas = MockCanvas();
    renderSystem.render(mockCanvas);

    expect(mockCanvas.drawRawAtlasCalled, isTrue);
  });
}
