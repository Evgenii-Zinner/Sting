import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/complex_ui.dart';
import 'package:sting/engine/ecs/component_caste.dart';

import '../../lib/components/health.dart';
import '../../lib/components/player_stats.dart';
import '../../lib/systems/player_stats_ui_system.dart';

void main() {
  group('PlayerStatsUISystem', () {
    test('updates ComplexUI text components correctly based on player stats', () {
      final scene = Scene();
      scene.registerCaste<Health>('Health', ComponentCaste<Health>(10));
      scene.registerCaste<PlayerStats>('PlayerStats', ComponentCaste<PlayerStats>(10));
      scene.registerCaste<ComplexUI>('ComplexUI', ComponentCaste<ComplexUI>(10));

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

      final complexUICaste = scene.getCaste<ComplexUI>('ComplexUI');
      complexUICaste.add(scoreId, ComplexUI(text: ""));
      complexUICaste.add(xpId, ComplexUI(text: ""));
      complexUICaste.add(healthId, ComplexUI(text: ""));

      final uiSystem = PlayerStatsUISystem(
        scene,
        scoreEntityId: scoreId,
        xpEntityId: xpId,
        healthEntityId: healthId,
      );

      uiSystem.update(player);

      expect(complexUICaste.get(scoreId)!.text, 'Score: 500');
      expect(complexUICaste.get(xpId)!.text, 'Lvl 2 | XP: 50 / 200');
      expect(complexUICaste.get(healthId)!.text, 'HP: 100/100');
    });
  });
}
