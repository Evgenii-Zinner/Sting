import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import '../../lib/components/enemy_ai.dart';

void main() {
  group('EnemyAI Component MVP Tests', () {
    test('creates and retrieves targetId correctly', () {
      final ai = EnemyAI.create(42);
      expect(ai.targetId, 42);

      ai.targetId = 15;
      expect(ai.targetId, 15);
    });

    test('works with ComponentCaste', () {
      final caste = ComponentCaste<EnemyAI>(10);
      caste.add(1, EnemyAI.create(99));

      final component = caste.get(1);
      expect(component, isNotNull);
      expect(component!.targetId, 99);
    });
  });
}
