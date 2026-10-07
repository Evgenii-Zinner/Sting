import 'dart:ui';
import 'dart:typed_data';
import '../ecs/query.dart';
import '../ecs/component_storage.dart';
import '../components/position.dart';
import '../components/viewport.dart';
import '../components/hex_edge_mesh.dart';
import '../math/hex_math.dart';

class HexEdgeRenderSystem {
  final Query1<HexEdgeMesh> querySingle;
  final Query2<Position, HexEdgeMesh> queryPositional;
  final ComponentStorage<Viewport>? viewportCaste;
  int activeCameraEntity;

  final Paint _paint;

  // Pre-allocated array for drawRawPoints.
  // Each segment needs 2 points (x, y) = 4 floats.
  final Float32List _points;

  HexEdgeRenderSystem({
    required ComponentStorage<HexEdgeMesh> hexEdgeMeshCaste,
    ComponentStorage<Position>? positionCaste,
    this.viewportCaste,
    this.activeCameraEntity = -1,
    int maxPointsPerBatch = 65535,
  })  : querySingle = Query1<HexEdgeMesh>(hexEdgeMeshCaste),
        queryPositional = positionCaste != null
            ? Query2<Position, HexEdgeMesh>(positionCaste, hexEdgeMeshCaste)
            : Query2<Position, HexEdgeMesh>(
                ComponentStorage<Position>(0), hexEdgeMeshCaste),
        _points = Float32List(maxPointsPerBatch * 4),
        _paint = Paint()
          ..isAntiAlias = true
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

  void render(Canvas canvas, [double scale = 1.0]) {
    bool hasViewport = false;
    double snappedVx = 0.0;
    double snappedVy = 0.0;

    if (activeCameraEntity != -1 && viewportCaste != null) {
      final viewport = viewportCaste!.get(activeCameraEntity);
      if (viewport != null) {
        hasViewport = true;
        canvas.save();
        canvas.scale(viewport.zoom, viewport.zoom);
        snappedVx = (viewport.x * scale).roundToDouble() / scale;
        snappedVy = (viewport.y * scale).roundToDouble() / scale;
        canvas.translate(-snappedVx, -snappedVy);
      }
    }

    void processMesh(HexEdgeMesh mesh, double startX, double startY) {
      final int edgeCount = mesh.edgeCount;
      if (edgeCount == 0) return;

      final bool isFlatTopped = mesh.isFlatTopped == 1;
      final double hexSize = mesh.hexSize;

      int currentBatchColor = 0;
      double currentBatchWidth = 0.0;
      int pointsInBatch = 0;

      void flushBatch() {
        if (pointsInBatch == 0) return;

        // drawRawPoints expects the list to be sized exactly to the points to draw
        canvas.drawRawPoints(
          PointMode.lines,
          Float32List.sublistView(_points, 0, pointsInBatch * 4),
          _paint,
        );
        pointsInBatch = 0;
      }

      for (int i = 0; i < edgeCount; i++) {
        final (q1, r1, q2, r2, color, width) = mesh.getEdge(i);

        // If paint attributes change or batch is full, flush
        if (pointsInBatch > 0 &&
            (color != currentBatchColor ||
                width != currentBatchWidth ||
                (pointsInBatch + 1) * 4 > _points.length)) {
          flushBatch();
        }

        if (pointsInBatch == 0) {
          currentBatchColor = color;
          currentBatchWidth = width;

          if (_paint.color.toARGB32() != color) {
            _paint.color = Color(color);
          }
          if (_paint.strokeWidth != width) {
            _paint.strokeWidth = width;
          }
        }

        final (hx1, hy1) = isFlatTopped
            ? HexMath.flatGridToWorld(q1, r1, hexSize)
            : HexMath.pointyGridToWorld(q1, r1, hexSize);

        final (hx2, hy2) = isFlatTopped
            ? HexMath.flatGridToWorld(q2, r2, hexSize)
            : HexMath.pointyGridToWorld(q2, r2, hexSize);

        final index = pointsInBatch * 4;
        _points[index] = startX + hx1;
        _points[index + 1] = startY + hy1;
        _points[index + 2] = startX + hx2;
        _points[index + 3] = startY + hy2;

        pointsInBatch++;
      }

      flushBatch();
    }

    // Track processed entities to avoid double rendering
    final processedEntities = <int>{};

    // Process positional meshes
    queryPositional.forEach((entity, position, mesh) {
      final double startX = (position.x * scale).roundToDouble() / scale;
      final double startY = (position.y * scale).roundToDouble() / scale;
      processMesh(mesh, startX, startY);
      processedEntities.add(entity);
    });

    // Process non-positional (absolute) meshes by filtering out those processed
    querySingle.forEach((entity, mesh) {
      if (!processedEntities.contains(entity)) {
        processMesh(mesh, 0.0, 0.0);
      }
    });

    if (hasViewport) {
      canvas.restore();
    }
  }
}
