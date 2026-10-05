import 'dart:math' as math;
import 'package:sting/engine/components/field_emitter.dart';
import 'package:sting/engine/components/ground_trail_field.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';

/// A system that splats continuous emission into grid buffers without allocations.
class FieldEmissionSystem {
  final ComponentStorage<Position> positionCaste;
  final ComponentStorage<FieldEmitter> emitterCaste;
  final Map<int, GroundTrailField> channels;

  FieldEmissionSystem({
    required this.positionCaste,
    required this.emitterCaste,
    required this.channels,
  });

  /// Updates the fields by applying emission from active FieldEmitters.
  void update(double dt) {
    if (dt <= 0.0) return;

    Query2(positionCaste, emitterCaste).forEach((entity, pos, emitter) {
      if (!emitter.isActive) return;

      final field = channels[emitter.targetChannel];
      if (field == null) return;

      final double radius = emitter.radius;
      if (radius <= 0.0) return;

      final double emissionValue = emitter.emissionRate * dt;
      final int falloffType = emitter.falloffType;

      // Determine bounding box for grid cells affected by radius
      final double minX = pos.x - radius;
      final double maxX = pos.x + radius;
      final double minY = pos.y - radius;
      final double maxY = pos.y + radius;

      final double cellSize = field.cellSize;
      if (cellSize <= 0.0) return;

      // Convert to grid space
      int minCol = ((minX - field.originX) / cellSize).floor();
      int maxCol = ((maxX - field.originX) / cellSize).floor();
      int minRow = ((minY - field.originY) / cellSize).floor();
      int maxRow = ((maxY - field.originY) / cellSize).floor();

      final int cols = field.columns.toInt();
      final int rows = field.rows.toInt();

      if (minCol < 0) minCol = 0;
      if (maxCol >= cols) maxCol = cols - 1;
      if (minRow < 0) minRow = 0;
      if (maxRow >= rows) maxRow = rows - 1;

      // Iterate through cells within the bounding box
      for (int row = minRow; row <= maxRow; row++) {
        for (int col = minCol; col <= maxCol; col++) {
          // World position of the cell's center
          final double cellWorldX =
              field.originX + col * cellSize + cellSize * 0.5;
          final double cellWorldY =
              field.originY + row * cellSize + cellSize * 0.5;

          final double dx = pos.x - cellWorldX;
          final double dy = pos.y - cellWorldY;
          final double distSq = dx * dx + dy * dy;
          final double radiusSq = radius * radius;

          if (distSq <= radiusSq) {
            final double dist = math.sqrt(distSq);
            double factor = 1.0;

            if (falloffType == 0) {
              // Bilinear
              factor = 1.0 - (dist / radius);
            } else if (falloffType == 1) {
              // Gaussian approximation
              final double normalizedDist = dist / radius;
              factor = math.exp(-3.0 * normalizedDist * normalizedDist);
            } else if (falloffType == 2) {
              // Flat
              factor = 1.0;
            }

            if (factor > 0.0) {
              field.addValue(col, row, emissionValue * factor);
            }
          }
        }
      }
    });
  }
}
