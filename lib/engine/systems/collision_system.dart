import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/circle_collider.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/math/intersection.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';

/// Callback type for collision events.
typedef CollisionCallback = void Function(int entityA, int entityB);

/// A system that detects narrow-phase collisions between entities using the
/// spatial hash grid for broad-phase culling.
class CollisionSystem {
  final SpatialHashGrid _grid;
  final ComponentCaste<Position> _positionCaste;
  final ComponentCaste<BoundingBox>? _boundingBoxCaste;
  final ComponentCaste<CircleCollider>? _circleColliderCaste;

  /// Creates a new CollisionSystem.
  CollisionSystem(
    this._grid,
    this._positionCaste, {
    ComponentCaste<BoundingBox>? boundingBoxCaste,
    ComponentCaste<CircleCollider>? circleColliderCaste,
  })  : _boundingBoxCaste = boundingBoxCaste,
        _circleColliderCaste = circleColliderCaste;

  /// Checks for collisions between two BoundingBoxes.
  /// Calls [onCollision] for each pair of colliding entities.
  void checkAABBAABB(CollisionCallback onCollision) {
    if (_boundingBoxCaste == null) return;

    final query =
        Query2<Position, BoundingBox>(_positionCaste, _boundingBoxCaste);

    query.forEach((entityA, posA, boxA) {
      _grid.queryAABB(posA.x, posA.y, boxA.width, boxA.height, (entityB) {
        // Prevent self-collision and duplicate pairs (e.g., A-B and B-A)
        if (entityA >= entityB) return true;

        final boxB = _boundingBoxCaste.get(entityB);
        if (boxB != null) {
          final posB = _positionCaste.get(entityB);

          if (posB != null &&
              intersectAABBAABB(
                posA.x,
                posA.y,
                boxA.width,
                boxA.height,
                posB.x,
                posB.y,
                boxB.width,
                boxB.height,
              )) {
            onCollision(entityA, entityB);
          }
        }
        return true; // Continue querying
      });
    });
  }

  /// Checks for collisions between two CircleColliders.
  /// Calls [onCollision] for each pair of colliding entities.
  void checkCircleCircle(CollisionCallback onCollision) {
    if (_circleColliderCaste == null) return;

    final query =
        Query2<Position, CircleCollider>(_positionCaste, _circleColliderCaste);

    query.forEach((entityA, posA, circleA) {
      // Query grid using a bounding box encompassing the circle
      final diameterA = circleA.radius * 2;
      _grid.queryAABB(
        posA.x - circleA.radius,
        posA.y - circleA.radius,
        diameterA,
        diameterA,
        (entityB) {
          // Prevent self-collision and duplicate pairs (e.g., A-B and B-A)
          if (entityA >= entityB) return true;

          final circleB = _circleColliderCaste.get(entityB);
          if (circleB != null) {
            final posB = _positionCaste.get(entityB);

            if (posB != null &&
                intersectCircleCircle(
                  posA.x,
                  posA.y,
                  circleA.radius,
                  posB.x,
                  posB.y,
                  circleB.radius,
                )) {
              onCollision(entityA, entityB);
            }
          }
          return true; // Continue querying
        },
      );
    });
  }

  /// Checks for collisions between BoundingBoxes and CircleColliders.
  /// Calls [onCollision] for each pair of colliding entities where A has BoundingBox and B has CircleCollider.
  void checkAABBCircle(CollisionCallback onCollision) {
    if (_boundingBoxCaste == null || _circleColliderCaste == null) return;

    final query =
        Query2<Position, BoundingBox>(_positionCaste, _boundingBoxCaste);

    query.forEach((entityA, posA, boxA) {
      // Query grid using the bounding box of entityA
      _grid.queryAABB(posA.x, posA.y, boxA.width, boxA.height, (entityB) {
        // Prevent self-collision. Note: A and B are of different types here,
        // so we don't do A >= B to prevent duplicates, but we do A == B.
        if (entityA == entityB) return true;

        final circleB = _circleColliderCaste.get(entityB);
        if (circleB != null) {
          final posB = _positionCaste.get(entityB);

          if (posB != null &&
              intersectAABBCircle(
                posA.x,
                posA.y,
                boxA.width,
                boxA.height,
                posB.x,
                posB.y,
                circleB.radius,
              )) {
            onCollision(entityA, entityB);
          }
        }
        return true; // Continue querying
      });
    });
  }
}
