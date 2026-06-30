import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/complex_ui.dart';
import '../components/player_stats.dart';
import '../components/health.dart';

/// A system that updates ComplexUI components on UI entities
/// based on the player's stats (Score, XP, Level, Health).
class PlayerStatsUISystem {
  final Scene _scene;
  final int _scoreEntityId;
  final int _xpEntityId;
  final int _healthEntityId;

  PlayerStatsUISystem(
    this._scene, {
    required int scoreEntityId,
    required int xpEntityId,
    required int healthEntityId,
  })  : _scoreEntityId = scoreEntityId,
        _xpEntityId = xpEntityId,
        _healthEntityId = healthEntityId;

  void update(int playerEntityId) {
    final statsCaste = _scene.getCaste<PlayerStats>('PlayerStats');
    final healthCaste = _scene.getCaste<Health>('Health');
    final complexUICaste = _scene.getCaste<ComplexUI>('ComplexUI');

    final playerStats = statsCaste.get(playerEntityId);
    final playerHealth = healthCaste.get(playerEntityId);

    if (playerStats != null) {
      final scoreUI = complexUICaste.get(_scoreEntityId);
      if (scoreUI != null) {
        scoreUI.text = 'Score: ${playerStats.score}';
      }

      final xpUI = complexUICaste.get(_xpEntityId);
      if (xpUI != null) {
        xpUI.text = 'Lvl ${playerStats.level} | XP: ${playerStats.xp} / ${playerStats.level * 100}';
      }
    }

    if (playerHealth != null) {
      final healthUI = complexUICaste.get(_healthEntityId);
      if (healthUI != null) {
        healthUI.text = 'HP: ${playerHealth.current}/${playerHealth.max}';
      }
    }
  }
}
