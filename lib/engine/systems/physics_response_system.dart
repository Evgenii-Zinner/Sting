import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/circle_collider.dart';
import 'package:sting/engine/components/mass.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/velocity.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/math/sat_collision.dart';
import 'package:sting/engine/systems/spatial_hash_grid.dart';

/// Resolves physics collisions (positional separation and velocity impulses)
/// using a broad-phase grid and narrow-phase SAT collision checks.
class PhysicsResponseSystem {
  final SpatialHashGrid _grid;
  final ComponentStorage<Position> _positionCaste;
  final ComponentStorage<Velocity> _velocityCaste;
  final ComponentStorage<Mass> _massCaste;
  final ComponentStorage<BoundingBox>? _boundingBoxCaste;
  final ComponentStorage<CircleCollider>? _circleColliderCaste;

  final SATCollisionResult _result = SATCollisionResult();

  // Pre-allocated buffers for contacts (to avoid per-frame allocations)
  final int _maxContacts;
  int _contactCount = 0;
  late final Int32List _contactEntityA;
  late final Int32List _contactEntityB;
  late final Float32List _contactNormalX;
  late final Float32List _contactNormalY;
  late final Float32List _contactDepth;

  /// Creates a new PhysicsResponseSystem.
  /// [maxContacts] defines the size of the pre-allocated contact buffers.
  PhysicsResponseSystem(
    this._grid,
    this._positionCaste,
    this._velocityCaste,
    this._massCaste, {
    ComponentStorage<BoundingBox>? boundingBoxCaste,
    ComponentStorage<CircleCollider>? circleColliderCaste,
    int maxContacts = 1024,
  })  : _boundingBoxCaste = boundingBoxCaste,
        _circleColliderCaste = circleColliderCaste,
        _maxContacts = maxContacts {
    _contactEntityA = Int32List(maxContacts);
    _contactEntityB = Int32List(maxContacts);
    _contactNormalX = Float32List(maxContacts);
    _contactNormalY = Float32List(maxContacts);
    _contactDepth = Float32List(maxContacts);
  }

  void _addContact(
      int entityA, int entityB, double nx, double ny, double depth) {
    if (_contactCount < _maxContacts) {
      _contactEntityA[_contactCount] = entityA;
      _contactEntityB[_contactCount] = entityB;
      _contactNormalX[_contactCount] = nx;
      _contactNormalY[_contactCount] = ny;
      _contactDepth[_contactCount] = depth;
      _contactCount++;
    }
  }

  /// Updates physics responses for all entities.
  void update() {
    _contactCount = 0;

    _findAABBAABBContacts();
    _findCircleCircleContacts();
    _findAABBCircleContacts();

    _resolveContacts();
  }

  void _findAABBAABBContacts() {
    if (_boundingBoxCaste == null) return;

    final query =
        Query2<Position, BoundingBox>(_positionCaste, _boundingBoxCaste);

    query.forEach((entityA, posA, boxA) {
      _grid.queryAABB(posA.x, posA.y, boxA.width, boxA.height, (entityB) {
        if (entityA >= entityB) return true; // prevent dupes/self

        final boxB = _boundingBoxCaste.get(entityB);
        if (boxB != null) {
          final posB = _positionCaste.get(entityB);
          if (posB != null) {
            testAABBAABB(posA.x, posA.y, boxA.width, boxA.height, posB.x,
                posB.y, boxB.width, boxB.height, _result);
            if (_result.intersects) {
              _addContact(entityA, entityB, _result.normalX, _result.normalY,
                  _result.depth);
            }
          }
        }
        return true;
      });
    });
  }

  void _findCircleCircleContacts() {
    if (_circleColliderCaste == null) return;

    final query =
        Query2<Position, CircleCollider>(_positionCaste, _circleColliderCaste);

    query.forEach((entityA, posA, circleA) {
      final diameter = circleA.radius * 2;
      _grid.queryAABB(
          posA.x - circleA.radius, posA.y - circleA.radius, diameter, diameter,
          (entityB) {
        if (entityA >= entityB) return true;

        final circleB = _circleColliderCaste.get(entityB);
        if (circleB != null) {
          final posB = _positionCaste.get(entityB);
          if (posB != null) {
            testCircleCircle(posA.x, posA.y, circleA.radius, posB.x, posB.y,
                circleB.radius, _result);
            if (_result.intersects) {
              _addContact(entityA, entityB, _result.normalX, _result.normalY,
                  _result.depth);
            }
          }
        }
        return true;
      });
    });
  }

  void _findAABBCircleContacts() {
    if (_boundingBoxCaste == null || _circleColliderCaste == null) return;

    final query =
        Query2<Position, BoundingBox>(_positionCaste, _boundingBoxCaste);

    query.forEach((entityA, posA, boxA) {
      _grid.queryAABB(posA.x, posA.y, boxA.width, boxA.height, (entityB) {
        if (entityA == entityB) return true;

        final circleB = _circleColliderCaste.get(entityB);
        if (circleB != null) {
          final posB = _positionCaste.get(entityB);
          if (posB != null) {
            testAABBCircle(posA.x, posA.y, boxA.width, boxA.height, posB.x,
                posB.y, circleB.radius, _result);
            if (_result.intersects) {
              _addContact(entityA, entityB, _result.normalX, _result.normalY,
                  _result.depth);
            }
          }
        }
        return true;
      });
    });
  }

  void _resolveContacts() {
    for (int i = 0; i < _contactCount; i++) {
      final entityA = _contactEntityA[i];
      final entityB = _contactEntityB[i];
      final nx = _contactNormalX[i];
      final ny = _contactNormalY[i];
      final depth = _contactDepth[i];

      final posA = _positionCaste.get(entityA);
      final posB = _positionCaste.get(entityB);
      final massA = _massCaste.get(entityA);
      final massB = _massCaste.get(entityB);

      if (posA == null || posB == null || massA == null || massB == null)
        continue;

      final invMassA = massA.inverseMass;
      final invMassB = massB.inverseMass;
      final totalInvMass = invMassA + invMassB;

      // If both are static (infinite mass), do nothing
      if (totalInvMass == 0.0) continue;

      // 1. Positional Separation (prevent sinking)
      // We apply a small slop to prevent jitter and a percent factor to smooth it.
      const double slop = 0.01;
      const double percent = 0.8; // 80% resolution per step
      final double correctionMagnitude =
          math.max(depth - slop, 0.0) / totalInvMass * percent;

      final cx = nx * correctionMagnitude;
      final cy = ny * correctionMagnitude;

      posA.x -= cx * invMassA;
      posA.y -= cy * invMassA;
      posB.x += cx * invMassB;
      posB.y += cy * invMassB;

      // 2. Velocity Impulse
      final velA = _velocityCaste.get(entityA);
      final velB = _velocityCaste.get(entityB);

      if (velA != null && velB != null) {
        // Relative velocity
        final rvx = velB.dx - velA.dx;
        final rvy = velB.dy - velA.dy;

        // Relative velocity along the normal
        final velAlongNormal = rvx * nx + rvy * ny;

        // Do not resolve if velocities are separating
        if (velAlongNormal > 0) continue;

        // Calculate restitution (bounciness) - use the minimum of both
        final e = math.min(massA.restitution, massB.restitution);

        // Calculate impulse scalar
        double j = -(1.0 + e) * velAlongNormal;
        j /= totalInvMass;

        // Apply impulse
        final impulseX = nx * j;
        final impulseY = ny * j;

        velA.dx -= impulseX * invMassA;
        velA.dy -= impulseY * invMassA;
        velB.dx += impulseX * invMassB;
        velB.dy += impulseY * invMassB;

        // 3. Friction
        // Recalculate relative velocity after normal impulse
        final rvx2 = velB.dx - velA.dx;
        final rvy2 = velB.dy - velA.dy;

        // Tangent vector
        double tx = rvx2 - (nx * (rvx2 * nx + rvy2 * ny));
        double ty = rvy2 - (ny * (rvx2 * nx + rvy2 * ny));

        // Normalize tangent
        double tLen = math.sqrt(tx * tx + ty * ty);
        if (tLen > 0.0001) {
          tx /= tLen;
          ty /= tLen;
        }

        // Relative velocity along tangent
        final velAlongTangent = rvx2 * tx + rvy2 * ty;

        // Calculate friction impulse scalar
        double jt = -velAlongTangent;
        jt /= totalInvMass;

        // Clamp friction using Coulomb's law (mu * normal force)
        final mu = math.sqrt(
            massA.friction * massA.friction + massB.friction * massB.friction);

        double frictionImpulseX;
        double frictionImpulseY;

        if (jt.abs() < j * mu) {
          frictionImpulseX = tx * jt;
          frictionImpulseY = ty * jt;
        } else {
          // Dynamic friction
          frictionImpulseX = tx * -j * mu;
          frictionImpulseY = ty * -j * mu;
        }

        velA.dx -= frictionImpulseX * invMassA;
        velA.dy -= frictionImpulseY * invMassA;
        velB.dx += frictionImpulseX * invMassB;
        velB.dy += frictionImpulseY * invMassB;
      }
    }
  }
}
