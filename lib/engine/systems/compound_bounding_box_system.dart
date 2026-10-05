import 'package:sting/engine/components/bounding_box.dart';
import 'package:sting/engine/components/compound_bounding_box.dart';
import 'package:sting/engine/components/local_transform.dart';
import 'package:sting/engine/components/parent.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'dart:math' as math;

class CompoundBoundingBoxSystem {
  final ComponentStorage<CompoundBoundingBox> compoundBoxCaste;
  final ComponentStorage<BoundingBox> boundingBoxCaste;
  final ComponentStorage<Parent> parentCaste;
  final ComponentStorage<Position> positionCaste;
  final ComponentStorage<LocalTransform> localTransformCaste;

  CompoundBoundingBoxSystem({
    required this.compoundBoxCaste,
    required this.boundingBoxCaste,
    required this.parentCaste,
    required this.positionCaste,
    required this.localTransformCaste,
  });

  void update() {
    final length = compoundBoxCaste.length;
    for (int i = 0; i < length; i++) {
      final entity = compoundBoxCaste.elementAt(i);
      final compoundBox = compoundBoxCaste.getComponentAt(i);
      if (compoundBox == null) continue;

      final boundingBox = boundingBoxCaste.get(entity);
      if (boundingBox == null) continue;

      final pos = positionCaste.get(entity);
      if (pos == null) continue;

      // Initialize with root's own initial bounds or center
      compoundBox.reset(pos.x, pos.y);

      // Add root's own bounding box to the initial bounds
      final halfWidth = boundingBox.width / 2;
      final halfHeight = boundingBox.height / 2;

      compoundBox.updateBounds(
        pos.x - halfWidth,
        pos.y - halfHeight,
        pos.x + halfWidth,
        pos.y + halfHeight,
      );

      _traverseChildren(entity, compoundBox, pos.x, pos.y);

      // Apply back to the root's bounding box with symmetric expansion
      // so it encapsulates asymmetric children while centered on pos
      final double maxOffsetX = math.max(pos.x - compoundBox.minX, compoundBox.maxX - pos.x);
      final double maxOffsetY = math.max(pos.y - compoundBox.minY, compoundBox.maxY - pos.y);

      boundingBox.width = maxOffsetX * 2;
      boundingBox.height = maxOffsetY * 2;
    }
  }

  void _traverseChildren(int parentEntity, CompoundBoundingBox rootCompoundBox, double parentWorldX, double parentWorldY) {
    final length = parentCaste.length;
    for (int i = 0; i < length; i++) {
      final childEntity = parentCaste.elementAt(i);
      final parent = parentCaste.getComponentAt(i);
      if (parent == null) continue;

      if (parent.entityId == parentEntity) {
        rootCompoundBox.childCount += 1.0;

        double childWorldX = parentWorldX;
        double childWorldY = parentWorldY;

        final childPos = positionCaste.get(childEntity);
        if (childPos != null) {
          childWorldX = childPos.x;
          childWorldY = childPos.y;
        } else {
          final childLocal = localTransformCaste.get(childEntity);
          if (childLocal != null) {
            childWorldX = parentWorldX + childLocal.lx;
            childWorldY = parentWorldY + childLocal.ly;
          }
        }

        final childBox = boundingBoxCaste.get(childEntity);
        if (childBox != null) {
          final hw = childBox.width / 2;
          final hh = childBox.height / 2;
          rootCompoundBox.updateBounds(
            childWorldX - hw,
            childWorldY - hh,
            childWorldX + hw,
            childWorldY + hh,
          );
        }

        // Recursively traverse for multi-generation children
        _traverseChildren(childEntity, rootCompoundBox, childWorldX, childWorldY);
      }
    }
  }
}
