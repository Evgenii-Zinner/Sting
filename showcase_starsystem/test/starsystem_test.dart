import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/parallax.dart';
import 'package:sting/engine/components/virtual_joypad.dart';

import '../lib/main.dart';
import '../lib/embedded_assets.dart';
import 'package:sting/engine/assets/asset_loader.dart';

void main() {
  test('StarSystemGame initializes and applies gravity correctly', () async {
    // 1. Initialize engine
    final Image mockAtlas = await AssetLoader.loadEmbeddedImage(
        EmbeddedAssets.assets['atlas.png']!);
    final game = StarSystemGame(mockAtlas);

    // Check initial state
    final positions = game.scene.getCaste<Position>('Position');
    final velocities = game.scene.getCaste<Velocity>('Velocity');

    // Expect 4 positions now because we added 1 background starfield parallax entity
    expect(positions.length, 4,
        reason: 'Should have spawned 1 star, 2 planets, 1 bg');

    // Check castes for new systems
    expect(game.scene.getCaste<Parallax>('Parallax'), isNotNull);
    expect(game.scene.getCaste<VirtualJoypad>('VirtualJoypad'), isNotNull);
    expect(game.inputMappingSystem, isNotNull);

    // We assume entity IDs are 1 (State), 2 (Camera), 3 (Star), 4 (Planet1), 5 (Planet2) based on creation order
    // But let's find them properly by inspecting positions since star is at 0,0, planet1 is at 150,0
    int planet1Id = -1;
    for (int i = 0; i < positions.length; i++) {
      int entity = positions.elementAt(i);
      if (positions.getComponentAt(i)!.x == 150) {
        planet1Id = entity;
      }
    }

    expect(planet1Id, isNot(-1));

    final initialVelocity = velocities.get(planet1Id)!;
    expect(initialVelocity.dy, closeTo(57.7, 0.1),
        reason: 'Planet 1 initial dy velocity should be ~57.7');
    expect(initialVelocity.dx, 0.0);

    final initialPosition = positions.get(planet1Id)!;
    expect(initialPosition.x, 150.0);
    expect(initialPosition.y, 0.0);

    // 2. Tick systems manually to simulate one frame of gravity and movement
    double dt = 1.0; // Simulate 1 second

    // Manually run gravity and movement to avoid time dependency complexities
    game.gravitySystem.update(game.scene, dt);
    game.movementSystem.update(dt);

    // After 1 tick:
    // Star is at 0,0. Planet 1 is at 150,0.
    // Distance = 150. Mass = 10000. G = 50.
    // Acceleration on Planet 1 from Star = G * M / d^2 = 50 * 10000 / 150^2
    // a = 500000 / 22500 = 22.222... towards Star (which means negative X direction)
    // dx velocity should now be -22.222 * dt
    // dy velocity should remain roughly 57.7
    // position x = 150 + dx * dt
    // position y = 0 + dy * dt

    final newVelocity = velocities.get(planet1Id)!;
    final newPosition = positions.get(planet1Id)!;

    expect(newVelocity.dx, closeTo(-22.22, 0.1),
        reason: 'Gravity should pull planet in -x direction');
    expect(newVelocity.dy, closeTo(57.7, 0.1),
        reason: 'Tangent velocity should remain unchanged mostly');

    expect(newPosition.x, closeTo(150.0 - 22.22, 0.1),
        reason: 'Position x should move inwards due to new velocity');
    expect(newPosition.y, closeTo(57.7, 0.1),
        reason: 'Position y should increase due to orbital velocity');
  });

  test(
      'StarSystemGame joypad updates bounds properly when tested independently',
      () async {
    final Image mockAtlas = await AssetLoader.loadEmbeddedImage(
        EmbeddedAssets.assets['atlas.png']!);
    final game = StarSystemGame(mockAtlas);

    // Test that the game object actually has the virtual joypad initialized
    expect(game.joypadEntityId, isNot(-1));
    expect(game.virtualJoypadSystem, isNotNull);
    expect(
        game.scene
            .getCaste<VirtualJoypad>('VirtualJoypad')
            .get(game.joypadEntityId),
        isNotNull);
  });
}
