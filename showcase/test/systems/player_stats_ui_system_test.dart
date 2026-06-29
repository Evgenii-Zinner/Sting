import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/text_render.dart';
import 'package:sting/engine/ecs/component_caste.dart';

import '../../lib/components/health.dart';
import '../../lib/components/player_stats.dart';
import '../../lib/systems/player_stats_ui_system.dart';

void main() {
  group('PlayerStatsUISystem', () {
    test('updates UI text components correctly based on player stats', () {
      final scene = Scene();
      scene.registerCaste<Health>('Health', ComponentCaste<Health>(10));
      scene.registerCaste<PlayerStats>('PlayerStats', ComponentCaste<PlayerStats>(10));
      scene.registerCaste<TextRender>('TextRender', ComponentCaste<TextRender>(10));

      final player = scene.createEntity();
      scene.getCaste<Health>('Health').add(player, Health.create(100));
      final stats = PlayerStats.create();
      stats.score = 500;
      stats.xp = 50;
      stats.level = 2;
      scene.getCaste<PlayerStats>('PlayerStats').add(player, stats);

      final scoreId = scene.createEntity();
      final xpId = scene.createEntity();
      final healthId = scene.createEntity();

      final textRenderCaste = scene.getCaste<TextRender>('TextRender');
      textRenderCaste.add(scoreId, TextRender(text: ""));
      textRenderCaste.add(xpId, TextRender(text: ""));
      textRenderCaste.add(healthId, TextRender(text: ""));

      final uiSystem = PlayerStatsUISystem(
        scene,
        scoreEntityId: scoreId,
        xpEntityId: xpId,
        healthEntityId: healthId,
      );

      uiSystem.update(player);

      expect(textRenderCaste.get(scoreId)!.text, 'Score: 500');
      expect(textRenderCaste.get(xpId)!.text, 'Lvl 2 | XP: 50 / 200');
      expect(textRenderCaste.get(healthId)!.text, 'HP: 100/100');
    });
  });
}
