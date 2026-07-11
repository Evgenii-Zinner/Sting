import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/components/utility_ai.dart';

/// A system that calculates the best utility action for entities with a [UtilityAI] component.
/// It iterates through parallel `tension` and `damping` arrays to compute a utility score
/// (score = tension - damping). The task with the highest score becomes the `activeTaskId`.
///
/// Hysteresis is applied to the currently active task to prevent rapid oscillation
/// between closely scored tasks.
class UtilityAISystem {
  final Scene _scene;
  late final Query1<UtilityAI> _query;

  /// The score bonus added to the currently active task to prevent oscillation.
  static const double hysteresisBonus = 0.1;

  UtilityAISystem(this._scene) {
    _query = Query1<UtilityAI>(_scene.getCaste<UtilityAI>('UtilityAI'));
  }

  void update(double dt) {
    _query.forEach((entity, ai) {
      final numConsiderations = ai.numConsiderations;
      final tension = ai.tension;
      final damping = ai.damping;

      int bestTask = -1;
      double bestScore = -double.maxFinite;

      final currentActiveTask = ai.activeTaskId;

      for (int i = 0; i < numConsiderations; i++) {
        double score = tension[i] - damping[i];

        // Apply hysteresis to the active task
        if (i == currentActiveTask) {
          score += hysteresisBonus;
        }

        if (score > bestScore) {
          bestScore = score;
          bestTask = i;
        }
      }

      if (bestTask != -1 && bestTask != currentActiveTask) {
        ai.activeTaskId = bestTask;
      }
    });
  }
}
