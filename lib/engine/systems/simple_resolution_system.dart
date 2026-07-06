import 'dart:math';

import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/circle_collider.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/component_caste.dart';

/// A system that resolves collisions by moving entities apart without adding jitter.
/// Does not use velocity or mass, just simple positional separation.
class SimpleResolutionSystem {
  final ComponentCaste<Position> _positionCaste;
  final ComponentCaste<BoundingBox>? _boundingBoxCaste;
  final ComponentCaste<CircleCollider>? _circleColliderCaste;

  SimpleResolutionSystem(
    this._positionCaste, {
    ComponentCaste<BoundingBox>? boundingBoxCaste,
    ComponentCaste<CircleCollider>? circleColliderCaste,
  })  : _boundingBoxCaste = boundingBoxCaste,
        _circleColliderCaste = circleColliderCaste;

  /// Separates two intersecting AABBs.
  void resolveAABBAABB(int entityA, int entityB) {
    if (_boundingBoxCaste == null) return;

    final posA = _positionCaste.get(entityA);
    final boxA = _boundingBoxCaste.get(entityA);
    final posB = _positionCaste.get(entityB);
    final boxB = _boundingBoxCaste.get(entityB);

    if (posA == null || boxA == null || posB == null || boxB == null) return;

    // Calculate centers
    final centerAx = posA.x + boxA.width / 2;
    final centerAy = posA.y + boxA.height / 2;
    final centerBx = posB.x + boxB.width / 2;
    final centerBy = posB.y + boxB.height / 2;

    // Calculate half extents
    final halfAWidth = boxA.width / 2;
    final halfAHeight = boxA.height / 2;
    final halfBWidth = boxB.width / 2;
    final halfBHeight = boxB.height / 2;

    // Calculate overlap on both axes
    final dx = centerBx - centerAx;
    final dy = centerBy - centerAy;

    final overlapX = halfAWidth + halfBWidth - dx.abs();
    final overlapY = halfAHeight + halfBHeight - dy.abs();

    // Only resolve if actually overlapping
    if (overlapX > 0 && overlapY > 0) {
      if (overlapX < overlapY) {
        // Resolve along X axis
        final shift = overlapX / 2;
        if (dx > 0) {
          // B is to the right of A
          posA.x -= shift;
          posB.x += shift;
        } else {
          // B is to the left of A
          posA.x += shift;
          posB.x -= shift;
        }
      } else {
        // Resolve along Y axis
        final shift = overlapY / 2;
        if (dy > 0) {
          // B is below A
          posA.y -= shift;
          posB.y += shift;
        } else {
          // B is above A
          posA.y += shift;
          posB.y -= shift;
        }
      }
    }
  }

  /// Separates two intersecting circles.
  void resolveCircleCircle(int entityA, int entityB) {
    if (_circleColliderCaste == null) return;

    final posA = _positionCaste.get(entityA);
    final circleA = _circleColliderCaste.get(entityA);
    final posB = _positionCaste.get(entityB);
    final circleB = _circleColliderCaste.get(entityB);

    if (posA == null || circleA == null || posB == null || circleB == null)
      return;

    final dx = posB.x - posA.x;
    final dy = posB.y - posA.y;
    final distanceSquared = dx * dx + dy * dy;
    final radiiSum = circleA.radius + circleB.radius;

    // Check if overlapping
    if (distanceSquared < radiiSum * radiiSum) {
      final distance = sqrt(distanceSquared);

      // Avoid division by zero if centers are exactly the same
      if (distance == 0.0) {
        // Push apart arbitrarily
        posA.x -= 0.1;
        posB.x += 0.1;
        return;
      }

      final overlap = radiiSum - distance;
      final shift = overlap / 2;

      final nx = dx / distance;
      final ny = dy / distance;

      posA.x -= nx * shift;
      posA.y -= ny * shift;
      posB.x += nx * shift;
      posB.y += ny * shift;
    }
  }

  /// Separates an intersecting AABB (entityA) and Circle (entityB).
  void resolveAABBCircle(int entityA, int entityB) {
    if (_boundingBoxCaste == null || _circleColliderCaste == null) return;

    final posA = _positionCaste.get(entityA);
    final boxA = _boundingBoxCaste.get(entityA);
    final posB =
        _positionCaste.get(entityB); // This is the center of the circle
    final circleB = _circleColliderCaste.get(entityB);

    if (posA == null || boxA == null || posB == null || circleB == null) return;

    // Find closest point on AABB to circle center
    var closestX = posB.x;
    if (closestX < posA.x) {
      closestX = posA.x;
    } else if (closestX > posA.x + boxA.width) {
      closestX = posA.x + boxA.width;
    }

    var closestY = posB.y;
    if (closestY < posA.y) {
      closestY = posA.y;
    } else if (closestY > posA.y + boxA.height) {
      closestY = posA.y + boxA.height;
    }

    // Distance from closest point to circle center
    final dx = posB.x - closestX;
    final dy = posB.y - closestY;
    final distanceSquared = dx * dx + dy * dy;

    // If center is inside AABB, distance is 0.
    // We need special handling for center inside AABB
    if (distanceSquared == 0) {
      // Find shortest path out
      final distToLeft = posB.x - posA.x;
      final distToRight = (posA.x + boxA.width) - posB.x;
      final distToTop = posB.y - posA.y;
      final distToBottom = (posA.y + boxA.height) - posB.y;

      final minX = distToLeft < distToRight ? distToLeft : distToRight;
      final minY = distToTop < distToBottom ? distToTop : distToBottom;

      if (minX < minY) {
        final pushOutX = minX + circleB.radius;
        final shift = pushOutX / 2;
        if (distToLeft < distToRight) {
          // Circle is closer to left edge
          posA.x += shift;
          posB.x -= shift;
        } else {
          // Circle is closer to right edge
          posA.x -= shift;
          posB.x += shift;
        }
      } else {
        final pushOutY = minY + circleB.radius;
        final shift = pushOutY / 2;
        if (distToTop < distToBottom) {
          // Circle is closer to top edge
          posA.y += shift;
          posB.y -= shift;
        } else {
          // Circle is closer to bottom edge
          posA.y -= shift;
          posB.y += shift;
        }
      }
    } else if (distanceSquared < circleB.radius * circleB.radius) {
      // Normal resolution (circle center outside AABB, but overlapping)
      final distance = sqrt(distanceSquared);
      final overlap = circleB.radius - distance;
      final shift = overlap / 2;

      final nx = dx / distance;
      final ny = dy / distance;

      posA.x -= nx * shift;
      posA.y -= ny * shift;
      posB.x += nx * shift;
      posB.y += ny * shift;
    }
  }
}
