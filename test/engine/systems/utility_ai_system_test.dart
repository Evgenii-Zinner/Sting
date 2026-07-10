import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/utility_ai.dart';
import 'package:sting/engine/systems/utility_ai_system.dart';

void main() {
  group('UtilityAISystem', () {
    late Scene scene;
    late UtilityAISystem system;

    setUp(() {
      scene = Scene();
      scene.registerCaste<UtilityAI>('UtilityAI', ComponentCaste<UtilityAI>(10));
      system = UtilityAISystem(scene);
    });

    test('updates active task based on best bid', () {
      final entity = scene.createEntity();
      final ai = UtilityAI.create(-1, -1, 0, 0, 3);

      ai.tension[0] = 0.5; ai.damping[0] = 0.1; // 0.4
      ai.tension[1] = 0.9; ai.damping[1] = 0.2; // 0.7 (Best)
      ai.tension[2] = 0.3; ai.damping[2] = 0.0; // 0.3

      scene.getCaste<UtilityAI>('UtilityAI').add(entity, ai);

      system.update(0.016);

      final updatedAi = scene.getCaste<UtilityAI>('UtilityAI').get(entity)!;
      expect(updatedAi.activeTaskId, 1);
    });

    test('applies hysteresis to prevent rapid switching', () {
      final entity = scene.createEntity();
      final ai = UtilityAI.create(0, -1, 0, 0, 2);

      ai.tension[0] = 0.5; ai.damping[0] = 0.0; // 0.5 (Base)
      ai.tension[1] = 0.55; ai.damping[1] = 0.0; // 0.55 (Better, but not enough to overcome hysteresis of 0.1)

      scene.getCaste<UtilityAI>('UtilityAI').add(entity, ai);

      system.update(0.016);

      final updatedAi = scene.getCaste<UtilityAI>('UtilityAI').get(entity)!;
      // Stays at 0 due to hysteresis (0.5 + 0.1 = 0.6 > 0.55)
      expect(updatedAi.activeTaskId, 0);

      // Now make Task 1 undeniably better (diff > 0.1)
      ai.tension[1] = 0.65; // Score 1 = 0.65. Task 0 = 0.5 + 0.1 = 0.6

      system.update(0.016);

      // Switches to 1
      expect(updatedAi.activeTaskId, 1);
    });

    test('does not change task if scores are negative but still handles correctly', () {
      final entity = scene.createEntity();
      final ai = UtilityAI.create(-1, -1, 0, 0, 2);

      ai.tension[0] = -0.5; ai.damping[0] = 0.0; // -0.5 (Best)
      ai.tension[1] = -0.9; ai.damping[1] = 0.0; // -0.9

      scene.getCaste<UtilityAI>('UtilityAI').add(entity, ai);

      system.update(0.016);

      final updatedAi = scene.getCaste<UtilityAI>('UtilityAI').get(entity)!;
      expect(updatedAi.activeTaskId, 0);
    });
  });
}
