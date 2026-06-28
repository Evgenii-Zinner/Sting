import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_caste.dart';

void main() {
  group('Velocity Component', () {
    test('create initializes dx and dy correctly', () {
      final vel = Velocity.create(10.5, 20.0);
      expect(vel.dx, 10.5);
      expect(vel.dy, 20.0);
    });

    test('getters and setters work correctly', () {
      final vel = Velocity.create(0, 0);
      vel.dx = -5.5;
      vel.dy = 42.1;
      expect(vel.dx, -5.5);
      expect(vel.dy, closeTo(42.1, 0.0001));
    });

    test('works with ComponentCaste', () {
      final caste = ComponentCaste<Velocity>(10);

      final vel1 = Velocity.create(1, 2);
      final vel2 = Velocity.create(3, 4);

      caste.add(0, vel1);
      caste.add(5, vel2);

      expect(caste.get(0)?.dx, 1);
      expect(caste.get(0)?.dy, 2);

      expect(caste.get(5)?.dx, 3);
      expect(caste.get(5)?.dy, 4);
    });
  });
}
