import 'package:flutter_test/flutter_test.dart';
import '../../lib/components/health.dart';
import '../../lib/components/damage.dart';
import '../../lib/components/exp_gem.dart';
import '../../lib/components/exp_magnet.dart';
import '../../lib/components/player_stats.dart';

void main() {
  group('Gameplay Components', () {
    test('Health component stores values correctly', () {
      final health = Health.create(100);
      expect(health.current, 100);
      expect(health.max, 100);

      health.current = 50;
      expect(health.current, 50);
    });

    test('Damage component stores values correctly', () {
      final damage = Damage.create(25);
      expect(damage.amount, 25);

      damage.amount = 30;
      expect(damage.amount, 30);
    });

    test('ExpGem component stores values correctly', () {
      final gem = ExpGem.create(15);
      expect(gem.xpValue, 15);

      gem.xpValue = 20;
      expect(gem.xpValue, 20);
    });

    test('ExpMagnet component stores values correctly', () {
      final magnet = ExpMagnet.create(50.5);
      expect(magnet.radius, 50.5);

      magnet.radius = 100.0;
      expect(magnet.radius, 100.0);
    });

    test('PlayerStats component stores values correctly', () {
      final stats = PlayerStats.create();
      expect(stats.score, 0);
      expect(stats.xp, 0);
      expect(stats.level, 1);

      stats.score = 500;
      stats.xp = 120;
      stats.level = 2;

      expect(stats.score, 500);
      expect(stats.xp, 120);
      expect(stats.level, 2);
    });
  });
}
