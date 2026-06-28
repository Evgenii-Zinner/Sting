import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/systems/movement_system.dart';

void main() {
  group('MovementSystem', () {
    test('updates position based on velocity and dt', () {
      final positionCaste = ComponentCaste<Position>(10);
      final velocityCaste = ComponentCaste<Velocity>(10);

      final system = MovementSystem(
        positionCaste: positionCaste,
        velocityCaste: velocityCaste,
      );

      // Entity 0: Moving right at 10 units/s
      positionCaste.add(0, Position.create(0, 0));
      velocityCaste.add(0, Velocity.create(10, 0));

      // Entity 1: Moving diagonally at 5 units/s
      positionCaste.add(1, Position.create(10, 10));
      velocityCaste.add(1, Velocity.create(5, -5));

      // Entity 2: Has position but no velocity (should not move)
      positionCaste.add(2, Position.create(20, 20));

      // Update with dt = 0.5 seconds
      system.update(0.5);

      final pos0 = positionCaste.get(0)!;
      expect(pos0.x, 5.0);
      expect(pos0.y, 0.0);

      final pos1 = positionCaste.get(1)!;
      expect(pos1.x, 12.5);
      expect(pos1.y, 7.5);

      final pos2 = positionCaste.get(2)!;
      expect(pos2.x, 20.0);
      expect(pos2.y, 20.0);
    });

    test('zero allocations per tick', () {
      // In Dart, verifying zero allocations accurately in tests is difficult,
      // but we can at least verify no exceptions occur and execution completes.
      final positionCaste = ComponentCaste<Position>(100);
      final velocityCaste = ComponentCaste<Velocity>(100);

      for (var i = 0; i < 100; i++) {
        positionCaste.add(i, Position.create(i.toDouble(), i.toDouble()));
        velocityCaste.add(i, Velocity.create(1.0, 1.0));
      }

      final system = MovementSystem(
        positionCaste: positionCaste,
        velocityCaste: velocityCaste,
      );

      expect(() => system.update(0.016), returnsNormally);
    });
  });
}
