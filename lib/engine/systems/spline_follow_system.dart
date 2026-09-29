import 'dart:math' as math;
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/components/spline_follower.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/math/polyline.dart';
import 'package:sting/engine/math/spline.dart';

/// A system that advances entities along a spline or polyline.
class SplineFollowSystem {
  final Query2<Position, SplineFollower> query;
  final ComponentCaste<Velocity>? velocityCaste;

  SplineFollowSystem({
    required ComponentCaste<Position> positionCaste,
    required ComponentCaste<SplineFollower> splineFollowerCaste,
    this.velocityCaste,
  }) : query = Query2<Position, SplineFollower>(positionCaste, splineFollowerCaste);

  void update(double dt) {
    query.forEach((entity, position, follower) {
      if (follower.pointCount == 0) return;

      final double distanceStep = follower.speed * dt * follower.direction;
      follower.currentDistance += distanceStep;

      double maxDistOrT = 1.0;
      if (follower.type == 0) { // Polyline
        maxDistOrT = PolylineMath.length(follower.points);
        if (maxDistOrT <= 0.0) return; // Cannot follow empty length
      }

      // Handle loop modes
      if (follower.loopMode == 0) {
        // Once
        if (follower.currentDistance > maxDistOrT) {
          follower.currentDistance = maxDistOrT;
        } else if (follower.currentDistance < 0.0) {
          follower.currentDistance = 0.0;
        }
      } else if (follower.loopMode == 1) {
        // Loop
        if (follower.currentDistance > maxDistOrT) {
          follower.currentDistance %= maxDistOrT;
        } else if (follower.currentDistance < 0.0) {
          follower.currentDistance = maxDistOrT - (-follower.currentDistance % maxDistOrT);
        }
      } else if (follower.loopMode == 2) {
        // Pingpong
        if (follower.currentDistance > maxDistOrT) {
          follower.currentDistance = maxDistOrT - (follower.currentDistance - maxDistOrT);
          follower.direction *= -1.0;
        } else if (follower.currentDistance < 0.0) {
          follower.currentDistance = -follower.currentDistance;
          follower.direction *= -1.0;
        }
      }

      // Evaluate new position
      (double, double) result = (0.0, 0.0);
      final double param = follower.currentDistance;

      if (follower.type == 0) {
        // Polyline (distance based)
        result = PolylineMath.evaluateAtDistance(follower.points, param);
      } else if (follower.type == 1 && follower.pointCount >= 3) {
        // Quadratic Bezier (t based)
        result = SplineMath.evaluateQuadraticBezier(
          follower.getPointX(0), follower.getPointY(0),
          follower.getPointX(1), follower.getPointY(1),
          follower.getPointX(2), follower.getPointY(2),
          param,
        );
      } else if (follower.type == 2 && follower.pointCount >= 4) {
        // Cubic Bezier (t based)
        result = SplineMath.evaluateCubicBezier(
          follower.getPointX(0), follower.getPointY(0),
          follower.getPointX(1), follower.getPointY(1),
          follower.getPointX(2), follower.getPointY(2),
          follower.getPointX(3), follower.getPointY(3),
          param,
        );
      } else if (follower.type == 3 && follower.pointCount >= 4) {
        // Hermite (t based, point format: p0, t0, p1, t1)
        result = SplineMath.evaluateHermite(
          follower.getPointX(0), follower.getPointY(0),
          follower.getPointX(1), follower.getPointY(1),
          follower.getPointX(2), follower.getPointY(2),
          follower.getPointX(3), follower.getPointY(3),
          param,
        );
      } else {
        // Fallback for missing points
        result = (follower.getPointX(0), follower.getPointY(0));
      }

      final double newX = result.$1;
      final double newY = result.$2;

      // Calculate tangent if velocity exists and we need to align
      if (velocityCaste != null && follower.alignRotation) {
        final velocity = velocityCaste!.get(entity);
        if (velocity != null) {
          final double dx = newX - position.x;
          final double dy = newY - position.y;
          // Set velocity proportional to dx/dy to match the step distance,
          // or normalize and multiply by speed if distance > 0
          final double distSq = dx * dx + dy * dy;
          if (distSq > 0.000001) {
            final double dist = math.sqrt(distSq);
            velocity.dx = (dx / dist) * follower.speed;
            velocity.dy = (dy / dist) * follower.speed;
          }
        }
      }

      // Update position
      position.prevX = position.x;
      position.prevY = position.y;
      position.x = newX;
      position.y = newY;
    });
  }
}
