import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/utility_ai.dart';
import 'package:sting/engine/ecs/component_caste.dart';

void main() {
  group('UtilityAI', () {
    test('create initializes values correctly', () {
      final ai = UtilityAI.create(1, 42, 100.0, 200.0, 3);

      expect(ai.activeTaskId, 1);
      expect(ai.targetEntityId, 42);
      expect(ai.targetX, 100.0);
      expect(ai.targetY, 200.0);
      expect(ai.numConsiderations, 3);

      expect(ai.tension.length, 3);
      expect(ai.damping.length, 3);
    });

    test('getters and setters work correctly', () {
      final ai = UtilityAI.create(0, 0, 0.0, 0.0, 2);

      ai.activeTaskId = 2;
      expect(ai.activeTaskId, 2);

      ai.targetEntityId = 55;
      expect(ai.targetEntityId, 55);

      ai.targetX = 300.0;
      expect(ai.targetX, 300.0);

      ai.targetY = 400.0;
      expect(ai.targetY, 400.0);

      final tension = ai.tension;
      tension[0] = 0.8;
      tension[1] = 0.5;

      expect(ai.tension[0], closeTo(0.8, 1e-6));
      expect(ai.tension[1], closeTo(0.5, 1e-6));

      final damping = ai.damping;
      damping[0] = 0.2;
      damping[1] = 0.1;

      expect(ai.damping[0], closeTo(0.2, 1e-6));
      expect(ai.damping[1], closeTo(0.1, 1e-6));
    });

    test('works with Caste', () {
      final caste = ComponentCaste<UtilityAI>(10);
      final ai = UtilityAI.create(3, 99, 10.0, 20.0, 1);
      ai.tension[0] = 0.9;
      ai.damping[0] = 0.05;

      caste.add(1, ai);

      expect(caste.get(1) != null, isTrue);

      final retrieved = caste.get(1)!;
      expect(retrieved.activeTaskId, 3);
      expect(retrieved.targetEntityId, 99);
      expect(retrieved.targetX, 10.0);
      expect(retrieved.targetY, 20.0);
      expect(retrieved.tension[0], closeTo(0.9, 1e-6));
      expect(retrieved.damping[0], closeTo(0.05, 1e-6));
    });
  });
}
