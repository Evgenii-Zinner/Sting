import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/text_render.dart';
import '../components/player_stats.dart';
import '../components/health.dart';

/// A system that updates TextRender components on UI entities
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
    final textRenderCaste = _scene.getCaste<TextRender>('TextRender');

    final playerStats = statsCaste.get(playerEntityId);
    final playerHealth = healthCaste.get(playerEntityId);

    if (playerStats != null) {
      final scoreText = textRenderCaste.get(_scoreEntityId);
      if (scoreText != null) {
        scoreText.text = 'Score: ${playerStats.score}';
      }

      final xpText = textRenderCaste.get(_xpEntityId);
      if (xpText != null) {
        xpText.text = 'Lvl ${playerStats.level} | XP: ${playerStats.xp} / ${playerStats.level * 100}';
      }
    }

    if (playerHealth != null) {
      final healthText = textRenderCaste.get(_healthEntityId);
      if (healthText != null) {
        healthText.text = 'HP: ${playerHealth.current}/${playerHealth.max}';
      }
    }
  }
}
