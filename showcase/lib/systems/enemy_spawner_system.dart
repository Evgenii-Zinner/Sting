import 'dart:math';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/components/viewport.dart';
import '../prefabs/enemy_prefab.dart';

/// Spawns enemies periodically outside the viewport bounds, tracking towards a target.
class EnemySpawnerSystem {
  final Scene scene;
  final double spawnInterval;

  double _timeSinceLastSpawn = 0.0;
  int _targetId = -1;
  final Random _random = Random();

  // Logical screen size, used for spawning bounds
  double screenWidth = 800.0;
  double screenHeight = 600.0;

  EnemySpawnerSystem(this.scene, {this.spawnInterval = 1.0});

  /// Sets the target entity ID (e.g., the player) for the spawned enemies to chase.
  void setTargetEntity(int targetId) {
    _targetId = targetId;
  }

  /// Updates the logical screen size for spawn calculations.
  void updateScreenSize(double width, double height) {
    screenWidth = width;
    screenHeight = height;
  }

  /// Updates the spawner, checking if enough time has passed to spawn a new enemy.
  void update(double dt) {
    if (_targetId == -1) return;

    _timeSinceLastSpawn += dt;

    if (_timeSinceLastSpawn >= spawnInterval) {
      _timeSinceLastSpawn = 0.0;
      _spawnEnemyOutsideViewport();
    }
  }

  void _spawnEnemyOutsideViewport() {
    // 1. Get viewport to know where to spawn outside of it
    final viewportCaste = scene.getCaste<Viewport>('Viewport');
    if (viewportCaste.length == 0) return;

    final viewportEntity = viewportCaste.elementAt(0);
    final viewport = viewportCaste.get(viewportEntity);
    if (viewport == null) return;

    // Viewport position is top-left
    final vx = viewport.x;
    final vy = viewport.y;

    // 2. Pick a random edge (0: top, 1: right, 2: bottom, 3: left)
    final edge = _random.nextInt(4);

    double spawnX = 0.0;
    double spawnY = 0.0;

    // Spawn margin outside the screen
    const double margin = 50.0;

    switch (edge) {
      case 0: // Top
        spawnX = vx + _random.nextDouble() * screenWidth;
        spawnY = vy - margin;
        break;
      case 1: // Right
        spawnX = vx + screenWidth + margin;
        spawnY = vy + _random.nextDouble() * screenHeight;
        break;
      case 2: // Bottom
        spawnX = vx + _random.nextDouble() * screenWidth;
        spawnY = vy + screenHeight + margin;
        break;
      case 3: // Left
        spawnX = vx - margin;
        spawnY = vy + _random.nextDouble() * screenHeight;
        break;
    }

    // 3. Spawn the enemy
    spawnEnemy(scene, spawnX, spawnY, _targetId);
  }
}
