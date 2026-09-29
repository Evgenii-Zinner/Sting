import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/slope_modifier.dart';
import 'package:sting/engine/components/height_map.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/slope_physics_system.dart';

void main() {
  group('SlopePhysicsSystem', () {
    late ComponentStorage<Position> positionCaste;
    late ComponentStorage<Velocity> velocityCaste;
    late ComponentStorage<SlopeModifier> slopeModifierCaste;
    late SlopePhysicsSystem system;
    late HeightMap slopeHeightMap;

    setUp(() {
      positionCaste = ComponentStorage<Position>(10);
      velocityCaste = ComponentStorage<Velocity>(10);
      slopeModifierCaste = ComponentStorage<SlopeModifier>(10);

      // Slope going up in the positive X direction (dx = 1)
      slopeHeightMap = HeightMap.create(
          columns: 2,
          rows: 2,
          cellWidth: 1.0,
          cellHeight: 1.0,
          defaultHeight: 0.0);
      slopeHeightMap.setElevationAtCell(1, 0, 1.0);
      slopeHeightMap.setElevationAtCell(1, 1, 1.0);

      system = SlopePhysicsSystem(
        positionCaste: positionCaste,
        velocityCaste: velocityCaste,
        slopeModifierCaste: slopeModifierCaste,
        heightMap: slopeHeightMap,
      );
    });

    test('Uphill motion experiences drag and slows down', () {
      positionCaste.add(0, Position.create(0.5, 0.5));
      velocityCaste.add(0, Velocity.create(10.0, 0.0)); // Moving uphill
      slopeModifierCaste.add(
          0,
          SlopeModifier.create(
            uphillResistance: 0.5,
            gravityPull: 0.0, // Isolate drag
          ));

      system.update(1.0);

      final vel = velocityCaste.get(0)!;
      // Uphill directional grade = 1.0
      // Factor = (1.0 - 1.0 * 0.5 * 1.0) = 0.5
      expect(vel.dx, closeTo(5.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));
      expect(slopeModifierCaste.get(0)!.isStuckOrSliding, 0.0);
    });

    test('Downhill motion experiences acceleration and speeds up', () {
      positionCaste.add(0, Position.create(0.5, 0.5));
      velocityCaste.add(0, Velocity.create(-10.0, 0.0)); // Moving downhill
      slopeModifierCaste.add(
          0,
          SlopeModifier.create(
            downhillBoost: 0.5,
            gravityPull: 0.0, // Isolate boost
          ));

      system.update(1.0);

      final vel = velocityCaste.get(0)!;
      // Downhill directional grade = -1.0
      // Boost = -(-1.0) * 0.5 * 1.0 = 0.5
      // vel.dx += -10 * 0.5 = -15.0
      expect(vel.dx, closeTo(-15.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));
      expect(slopeModifierCaste.get(0)!.isStuckOrSliding, 0.0);
    });

    test('Gravitational sliding on incline when stationary', () {
      positionCaste.add(0, Position.create(0.5, 0.5));
      velocityCaste.add(0, Velocity.create(0.0, 0.0)); // Stationary
      slopeModifierCaste.add(
          0,
          SlopeModifier.create(
            gravityPull: 9.8,
            downhillBoost: 0.0, // Isolate gravity without compounding boost
            slideThreshold: 0.5, // Slope m=1.0 > 0.5, so will slide
          ));

      system.update(1.0);

      final vel = velocityCaste.get(0)!;
      // Gravity applied: vel.dx -= gx * 9.8 * 1.0 = -9.8
      expect(vel.dx, closeTo(-9.8, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));

      // The system should detect slide condition if initial vel = 0
      expect(slopeModifierCaste.get(0)!.isStuckOrSliding, 1.0);
    });

    test('Unclimbable steep slope deflects/blocks uphill progress', () {
      positionCaste.add(0, Position.create(0.5, 0.5));
      velocityCaste.add(0, Velocity.create(10.0, 0.0)); // Moving uphill
      slopeModifierCaste.add(
          0,
          SlopeModifier.create(
            uphillResistance: 0.0, // No drag, just pure slope blocking
            gravityPull: 0.0,
            maxClimbableSlope: 0.5, // Slope m=1.0 > 0.5, unclimbable
          ));

      system.update(1.0);

      final vel = velocityCaste.get(0)!;
      // Uphill progress blocked.
      // u_dot_v = (1*10 + 0*0) / (1^2) = 10
      // vel.dx = 10 - 10*1 = 0
      expect(vel.dx, closeTo(0.0, 0.001));
      expect(vel.dy, closeTo(0.0, 0.001));
      expect(slopeModifierCaste.get(0)!.isStuckOrSliding, 1.0);
    });

    test('Zero allocation execution during update', () {
      final bigPosCaste = ComponentStorage<Position>(100);
      final bigVelCaste = ComponentStorage<Velocity>(100);
      final bigSlopeCaste = ComponentStorage<SlopeModifier>(100);

      for (int i = 0; i < 100; i++) {
        bigPosCaste.add(i, Position.create(0.5, 0.5));
        bigVelCaste.add(i, Velocity.create(10.0, 0.0));
        bigSlopeCaste.add(i, SlopeModifier.create());
      }

      final bigSystem = SlopePhysicsSystem(
        positionCaste: bigPosCaste,
        velocityCaste: bigVelCaste,
        slopeModifierCaste: bigSlopeCaste,
        heightMap: slopeHeightMap,
      );

      // We expect the update to run without throwing and without triggering any heap allocations inside the loop.
      expect(() => bigSystem.update(0.016), returnsNormally);
    });
  });
}
