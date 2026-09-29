import 'package:sting/engine/components/ground_trail_field.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/trail_emitter.dart';
import 'package:sting/engine/components/trail_feedback.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';

/// A system that manages GroundTrailField decay, TrailEmitter deposition, and TrailFeedback activation.
class GroundTrailSystem {
  final ComponentStorage<GroundTrailField> fieldCaste;
  final ComponentStorage<Position> positionCaste;
  final ComponentStorage<TrailEmitter> emitterCaste;
  final ComponentStorage<TrailFeedback> feedbackCaste;

  GroundTrailSystem({
    required this.fieldCaste,
    required this.positionCaste,
    required this.emitterCaste,
    required this.feedbackCaste,
  });

  /// Updates the ground trail system by applying decay, deposition, and evaluating feedback.
  void update(double dt) {
    if (dt <= 0.0) return;

    // We process the first available GroundTrailField (typically there's only one active in a region/scene).
    GroundTrailField? field;
    Query1(fieldCaste).forEach((entity, f) {
      field ??= f;
    });

    if (field == null) return;
    final GroundTrailField activeField = field!;

    // 1. Decay the field
    double decayAmount = activeField.decayRate * dt;
    if (decayAmount > 0) {
      int cols = activeField.columns.toInt();
      int rws = activeField.rows.toInt();
      for (int r = 0; r < rws; r++) {
        for (int c = 0; c < cols; c++) {
          double val = activeField.getValue(c, r);
          if (val > 0.0) {
            val -= decayAmount;
            if (val < 0.0) val = 0.0;
            activeField.setValue(c, r, val);
          }
        }
      }
    }

    // 2. Deposition from emitters
    Query2(positionCaste, emitterCaste).forEach((entity, pos, emitter) {
      if (!emitter.isActive) return;

      double x = pos.x;
      double y = pos.y;

      // Calculate discrete cell coordinates
      int col = ((x - activeField.originX) / activeField.cellSize).floor();
      int row = ((y - activeField.originY) / activeField.cellSize).floor();

      activeField.addValue(col, row, emitter.depositionRate * dt);
    });

    // 3. Evaluate feedback
    Query2(positionCaste, feedbackCaste).forEach((entity, pos, feedback) {
      // Query local ground value. The requirements specify querying "local ground value"
      // (which could be sampleValue or getValue of current cell).
      // We will use discrete cell value to match deposition's precision by default,
      // or sampleValue if continuous is preferred.
      // We'll use get value at discrete cell as it's the exact ground they stand on,
      // but sampleValue works better for smooth transitions.
      // Requirement: "query local ground value". Let's use getValue of the exact cell.

      int col = ((pos.x - activeField.originX) / activeField.cellSize).floor();
      int row = ((pos.y - activeField.originY) / activeField.cellSize).floor();

      double groundValue = activeField.getValue(col, row);

      if (groundValue >= feedback.threshold) {
        feedback.isOnTrail = true;
      } else {
        feedback.isOnTrail = false;
      }
    });
  }
}
