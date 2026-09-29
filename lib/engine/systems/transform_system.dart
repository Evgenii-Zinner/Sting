import 'dart:math' as math;
import 'dart:typed_data';
import 'package:sting/engine/components/local_transform.dart';
import 'package:sting/engine/components/parent.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/rotation.dart';
import 'package:sting/engine/components/scale.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/ecs/entity_manager.dart';
import 'package:sting/engine/ecs/query.dart';

class TransformSystem {
  final ComponentStorage<Parent> parentCaste;
  final ComponentStorage<LocalTransform> localTransformCaste;
  final ComponentStorage<Position> positionCaste;
  final ComponentStorage<Rotation>? rotationCaste;
  final ComponentStorage<Scale>? scaleCaste;

  // Pre-allocated array to track resolved state during the update pass.
  // We use bits in a Uint32List for zero-allocation state tracking.
  final Uint32List _resolvedFlags = Uint32List((EntityManager.maxEntities + 1) ~/ 32 + 1);
  final Uint32List _processingFlags = Uint32List((EntityManager.maxEntities + 1) ~/ 32 + 1);

  late final Query2<LocalTransform, Parent> _query;

  TransformSystem({
    required this.parentCaste,
    required this.localTransformCaste,
    required this.positionCaste,
    this.rotationCaste,
    this.scaleCaste,
  }) {
    _query = Query2(localTransformCaste, parentCaste);
  }

  void update() {
    // Clear flags
    for (int i = 0; i < _resolvedFlags.length; i++) {
      _resolvedFlags[i] = 0;
      _processingFlags[i] = 0;
    }

    _query.forEach((entity, local, parent) {
      _resolveEntity(entity, local, parent);
    });
  }

  void _resolveEntity(int entity, LocalTransform local, Parent parent) {
    final intIndex = entity ~/ 32;
    final bitIndex = entity % 32;

    if ((_resolvedFlags[intIndex] & (1 << bitIndex)) != 0) {
      return; // Already resolved
    }

    if ((_processingFlags[intIndex] & (1 << bitIndex)) != 0) {
      // Cycle detected! Break to prevent infinite loop.
      return;
    }

    // Mark as processing
    _processingFlags[intIndex] |= (1 << bitIndex);

    final parentId = parent.entityId;

    // Check if parent has a local transform and parent component
    final parentLocal = localTransformCaste.get(parentId);
    final parentParent = parentCaste.get(parentId);

    if (parentLocal != null && parentParent != null) {
      // Recursively resolve parent first
      _resolveEntity(parentId, parentLocal, parentParent);
    }

    // Now parent's world transform is guaranteed to be up to date (in Position, Rotation, Scale)
    // Compute this entity's world transform
    final parentPos = positionCaste.get(parentId);
    final parentRot = rotationCaste?.get(parentId);
    final parentScale = scaleCaste?.get(parentId);

    double pX = parentPos?.x ?? 0.0;
    double pY = parentPos?.y ?? 0.0;
    double pRot = parentRot?.radians ?? 0.0;
    double pScaleX = parentScale?.x ?? 1.0;
    double pScaleY = parentScale?.y ?? 1.0;

    // Apply transformations
    // 1. Scale
    double worldScaleX = pScaleX * local.localScaleX;
    double worldScaleY = pScaleY * local.localScaleY;

    // 2. Rotation
    double worldRot = pRot + local.localRotation;

    // 3. Translation (Local position rotated and scaled by parent, then translated by parent)
    double scaledLx = local.lx * pScaleX;
    double scaledLy = local.ly * pScaleY;

    double cosR = math.cos(pRot);
    double sinR = math.sin(pRot);

    double rotatedLx = scaledLx * cosR - scaledLy * sinR;
    double rotatedLy = scaledLx * sinR + scaledLy * cosR;

    double worldX = pX + rotatedLx;
    double worldY = pY + rotatedLy;

    // Write results
    var pos = positionCaste.get(entity);
    if (pos != null) {
      pos.prevX = pos.x;
      pos.prevY = pos.y;
      pos.x = worldX;
      pos.y = worldY;
    }

    if (rotationCaste != null) {
      var rot = rotationCaste!.get(entity);
      if (rot != null) {
        rot.radians = worldRot;
      }
    }

    if (scaleCaste != null) {
      var scale = scaleCaste!.get(entity);
      if (scale != null) {
        scale.x = worldScaleX;
        scale.y = worldScaleY;
      }
    }

    // Mark as resolved, unmark processing
    _resolvedFlags[intIndex] |= (1 << bitIndex);
    _processingFlags[intIndex] &= ~(1 << bitIndex);
  }
}

