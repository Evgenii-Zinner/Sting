import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/component_caste.dart';

void main() {
  group('Position Component', () {
    test('create initializes values correctly', () {
      final pos = Position.create(10.5, 20.0);
      expect(pos.x, 10.5);
      expect(pos.y, 20.0);
    });

    test('getters and setters update underlying memory', () {
      final pos = Position.create(0, 0);

      pos.x = -5.0;
      pos.y = 100.0;

      expect(pos.x, -5.0);
      expect(pos.y, 100.0);
    });

    test('can be stored in ComponentCaste without issues', () {
      final caste = ComponentCaste<Position>(10);

      final pos1 = Position.create(1, 2);
      final pos2 = Position.create(3, 4);

      caste.add(0, pos1);
      caste.add(1, pos2);

      final retrievedPos1 = caste.get(0);
      final retrievedPos2 = caste.get(1);

      expect(retrievedPos1, isNotNull);
      expect(retrievedPos1!.x, 1.0);
      expect(retrievedPos1.y, 2.0);

      expect(retrievedPos2, isNotNull);
      expect(retrievedPos2!.x, 3.0);
      expect(retrievedPos2.y, 4.0);

      // Modification through retrieved reference should mutate the stored structure
      retrievedPos1.x = 100.0;
      expect(caste.get(0)!.x, 100.0);
    });
  });
}
