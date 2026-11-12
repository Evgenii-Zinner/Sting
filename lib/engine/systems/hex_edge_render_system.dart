import 'dart:ui';
import 'dart:typed_data';
import '../ecs/query.dart';
import '../ecs/component_storage.dart';
import '../components/position.dart';
import '../components/viewport.dart';
import '../components/hex_edge_mesh.dart';
import '../math/hex_math.dart';

/// Renders hexagonal edge meshes ([HexEdgeMesh]) using batch line drawing.
///
/// Supports world-positioned meshes (paired with [Position]) and absolute meshes.
/// Batches line drawing using [Canvas.drawRawPoints] with zero heap allocations per frame.
class HexEdgeRenderSystem {
  /// Query for entities having only [HexEdgeMesh].
  final Query1<HexEdgeMesh> querySingle;

  /// Query for entities having both [Position] and [HexEdgeMesh].
  final Query2<Position, HexEdgeMesh> queryPositional;

  /// Optional storage for camera viewports.
  final ComponentStorage<Viewport>? viewportCaste;

  /// Entity ID of the active camera, or -1 if no camera is active.
  int activeCameraEntity;

  final Paint _paint;

  // Pre-allocated array for drawRawPoints.
  // Each segment needs 2 points (x, y) = 4 floats.
  final Float32List _points;

  // Pre-allocated set to track entities across queries without per-frame allocations.
  final Set<int> _processedEntities = <int>{};

  /// Creates a new [HexEdgeRenderSystem].
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

  /// Renders all edge meshes to the [canvas] at the specified subpixel [scale].
  void render(Canvas canvas, [double scale = 1.0]) {
    final hasViewport =
        Viewport.applyCamera(canvas, activeCameraEntity, viewportCaste, scale);

    void processMesh(HexEdgeMesh mesh, double startX, double startY) {
      final int edgeCount = mesh.edgeCount;
      if (edgeCount == 0) return;

      final bool isFlatTopped = mesh.isFlatTopped == 1;
      final double hexSize = mesh.hexSize;
      final uint32View = mesh.uint32View;

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
        final (q1, r1, q2, r2, color, width) = mesh.getEdge(i, uint32View);

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

    _processedEntities.clear();

    // Process positional meshes
    queryPositional.forEach((entity, position, mesh) {
      final double startX = Viewport.snapToPixel(position.x, scale);
      final double startY = Viewport.snapToPixel(position.y, scale);
      processMesh(mesh, startX, startY);
      _processedEntities.add(entity);
    });

    // Process non-positional (absolute) meshes by filtering out those processed
    querySingle.forEach((entity, mesh) {
      if (!_processedEntities.contains(entity)) {
        processMesh(mesh, 0.0, 0.0);
      }
    });

    if (hasViewport) {
      canvas.restore();
    }
  }
}
