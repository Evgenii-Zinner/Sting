import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/slope_modifier.dart';
import 'package:sting/engine/components/height_map.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';
import 'dart:math';

class SlopePhysicsSystem {
  final Query3<Position, Velocity, SlopeModifier> _query;
  HeightMap? heightMap;

  SlopePhysicsSystem({
    required ComponentStorage<Position> positionCaste,
    required ComponentStorage<Velocity> velocityCaste,
    required ComponentStorage<SlopeModifier> slopeModifierCaste,
    this.heightMap,
  }) : _query = Query3<Position, Velocity, SlopeModifier>(
          positionCaste,
          velocityCaste,
          slopeModifierCaste,
        );

  void update(double dt) {
    if (heightMap == null) return;

    _query.forEach((entity, pos, vel, slopeMod) {
      if (pos.x < 0 ||
          pos.x >= heightMap!.width * heightMap!.scaleX ||
          pos.y < 0 ||
          pos.y >= heightMap!.height * heightMap!.scaleY) {
        slopeMod.currentSlopeGrade = 0.0;
        slopeMod.currentSlopeAngle = 0.0;
        slopeMod.isStuckOrSliding = 0.0;
        return;
      }

      final (gx, gy) = heightMap!.getGradientAt(pos.x, pos.y);
      final double m = sqrt(gx * gx + gy * gy);
      final double theta = atan(m);

      // Save previous velocity to detect if it was stationary before gravity
      final double prevS = sqrt(vel.dx * vel.dx + vel.dy * vel.dy);

      vel.dx -= gx * slopeMod.gravityPull * dt;
      vel.dy -= gy * slopeMod.gravityPull * dt;

      final double currentS = sqrt(vel.dx * vel.dx + vel.dy * vel.dy);

      if (currentS > 1e-6) {
        final double gDir = (vel.dx * gx + vel.dy * gy) / currentS;

        if (gDir > 0) {
          final double factor = (1.0 - gDir * slopeMod.uphillResistance * dt).clamp(0.0, 1.0);
          vel.dx *= factor;
          vel.dy *= factor;

          if (m > slopeMod.maxClimbableSlope) {
            final double uDotV = (gx * vel.dx + gy * vel.dy) / (m * m);
            if (uDotV > 0) {
              vel.dx -= uDotV * gx;
              vel.dy -= uDotV * gy;
            }
            slopeMod.isStuckOrSliding = 1.0;
          } else {
            slopeMod.isStuckOrSliding = 0.0;
          }
        } else if (gDir < 0) {
          final double boost = -gDir * slopeMod.downhillBoost * dt;
          vel.dx += vel.dx * boost;
          vel.dy += vel.dy * boost;
          // Only slide if it was stationary, otherwise normal downhill movement
          if (prevS <= 1e-6 && m > slopeMod.slideThreshold) {
            slopeMod.isStuckOrSliding = 1.0;
          } else {
            slopeMod.isStuckOrSliding = 0.0;
          }
        } else {
          slopeMod.isStuckOrSliding = 0.0;
        }
        slopeMod.currentSlopeGrade = gDir;
      } else {
        slopeMod.currentSlopeGrade = 0.0;
        if (m > slopeMod.slideThreshold) {
          slopeMod.isStuckOrSliding = 1.0;
        } else {
          slopeMod.isStuckOrSliding = 0.0;
        }
      }

      slopeMod.currentSlopeAngle = theta;
    });
  }
}
