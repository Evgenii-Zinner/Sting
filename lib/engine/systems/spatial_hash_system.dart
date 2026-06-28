import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';

/// An ECS System that updates the spatial hash grid every frame based on entity positions.
class SpatialHashSystem {
  final SpatialHashGrid _grid;

  /// Creates a SpatialHashSystem that updates the given [_grid].
  SpatialHashSystem(this._grid);

  /// Updates the spatial hash grid.
  /// Iterates through [query] and inserts all valid entities into the grid.
  /// Ensures zero allocations per update.
  void update(Query1<Position> query) {
    // 1. Clear the grid from the previous frame.
    // O(numCells) time complexity, no allocation.
    _grid.clear();

    // 2. Repopulate the grid with current positions.
    // O(activeEntities) time complexity, no allocation.
    query.forEach((entity, position) {
      _grid.insert(entity, position.x, position.y);
    });
  }
}
