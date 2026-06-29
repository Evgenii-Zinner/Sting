import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';

import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/swarm.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/sprite.dart';
import 'package:sting/engine/components/sprite_animation.dart';
import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/systems/input_system.dart';
import '../lib/components/weapon.dart';

import '../lib/prefabs/player_prefab.dart';
import '../lib/systems/player_input_system.dart';

void main() {
  group('Player Movement MVP Tests', () {
    late Scene scene;

    setUp(() {
      scene = Scene();
      scene.registerCaste<Position>('Position', ComponentCaste<Position>(Swarm.maxEntities));
      scene.registerCaste<Velocity>('Velocity', ComponentCaste<Velocity>(Swarm.maxEntities));
      scene.registerCaste<Sprite>('Sprite', ComponentCaste<Sprite>(Swarm.maxEntities));
      scene.registerCaste<SpriteAnimation>('SpriteAnimation', ComponentCaste<SpriteAnimation>(Swarm.maxEntities));
      scene.registerCaste<BoundingBox>('BoundingBox', ComponentCaste<BoundingBox>(Swarm.maxEntities));
    scene.registerCaste<Weapon>('Weapon', ComponentCaste<Weapon>(Swarm.maxEntities));
    });

    test('spawnPlayer creates entity with correct components', () {
      final playerId = spawnPlayer(scene, 10.0, 20.0);

      expect(playerId, isNot(-1));

      final pos = scene.getCaste<Position>('Position').get(playerId);
      expect(pos, isNotNull);
      expect(pos!.x, closeTo(10.0, 0.001));
      expect(pos.y, closeTo(20.0, 0.001));

      final vel = scene.getCaste<Velocity>('Velocity').get(playerId);
      expect(vel, isNotNull);
      expect(vel!.dx, closeTo(0.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));

      final sprite = scene.getCaste<Sprite>('Sprite').get(playerId);
      expect(sprite, isNotNull);

      final anim = scene.getCaste<SpriteAnimation>('SpriteAnimation').get(playerId);
      expect(anim, isNotNull);
      expect(anim!.frameCount, 4);

      final box = scene.getCaste<BoundingBox>('BoundingBox').get(playerId);
      expect(box, isNotNull);
      expect(box!.width, 16.0);
      expect(box.height, 24.0);
    });

    test('PlayerInputSystem updates velocity based on virtual joystick input', () {
      // 1. Setup InputSystem manually (don't hook platform dispatcher for testing)
      final inputSystem = InputSystem(hook: false);

      // 2. Setup PlayerInputSystem
      final playerInputSystem = PlayerInputSystem(
        inputSystem: inputSystem,
        velocityCaste: scene.getCaste<Velocity>('Velocity'),
      );
      playerInputSystem.updateScreenSize(800.0, 600.0); // Center is 400, 300

      // 3. Spawn player and set entity
      final playerId = spawnPlayer(scene, 0.0, 0.0);
      playerInputSystem.setPlayerEntity(playerId);

      final velocity = scene.getCaste<Velocity>('Velocity').get(playerId)!;

      // Ensure initial velocity is zero
      playerInputSystem.update();
      expect(velocity.dx, closeTo(0.0, 0.001));
      expect(velocity.dy, closeTo(0.0, 0.001));

      // Simulate pointer down event at (500, 300) -> right of center
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(
          change: PointerChange.down,
          device: 1,
          physicalX: 500.0,
          physicalY: 300.0,
        )
      ]));

      // Update input system - should set velocity to move right at max speed
      playerInputSystem.update();
      expect(velocity.dx, closeTo(playerInputSystem.speed, 0.001));
      expect(velocity.dy, closeTo(0.0, 0.001));

      // Simulate pointer move event at (400, 200) -> above center
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(
          change: PointerChange.move,
          device: 1,
          physicalX: 400.0,
          physicalY: 200.0,
        )
      ]));

      // Update input system - should set velocity to move up at max speed
      playerInputSystem.update();
      expect(velocity.dx, closeTo(0.0, 0.001));
      expect(velocity.dy, closeTo(-playerInputSystem.speed, 0.001));

      // Simulate pointer up event -> release
      inputSystem.handlePacket(PointerDataPacket(data: [
        PointerData(
          change: PointerChange.up,
          device: 1,
          physicalX: 400.0,
          physicalY: 200.0,
        )
      ]));

      // Update input system - should reset velocity to zero
      playerInputSystem.update();
      expect(velocity.dx, closeTo(0.0, 0.001));
      expect(velocity.dy, closeTo(0.0, 0.001));
    });
  });
}
