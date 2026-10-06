import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/components/hex_edge_mesh.dart';
import 'dart:typed_data';
import 'package:sting/engine/systems/hex_edge_render_system.dart';
import 'package:sting/engine/math/hex_math.dart';

// Mock Canvas for verifying operations without full Skia execution
class MockCanvas implements Canvas {
  int drawRawPointsCalls = 0;
  int saveCalls = 0;
  int restoreCalls = 0;
  int scaleCalls = 0;
  int translateCalls = 0;

  Float32List? lastPoints;
  Paint? lastPaint;
  PointMode? lastPointMode;

  @override
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint) {
    drawRawPointsCalls++;
    lastPointMode = pointMode;
    lastPoints = Float32List.fromList(points); // Copy to retain state

    // Copy paint properties for verification
    lastPaint = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = paint.style;
  }

  @override
  void save() => saveCalls++;

  @override
  void restore() => restoreCalls++;

  @override
  void scale(double sx, [double? sy]) => scaleCalls++;

  @override
  void translate(double dx, double dy) => translateCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HexEdgeRenderSystem', () {
    late ComponentStorage<HexEdgeMesh> meshCaste;
    late ComponentStorage<Position> positionCaste;
    late ComponentStorage<Viewport> viewportCaste;

    setUp(() {
      meshCaste = ComponentStorage<HexEdgeMesh>(10);
      positionCaste = ComponentStorage<Position>(10);
      viewportCaste = ComponentStorage<Viewport>(10);
    });

    test('renders absolute meshes in batched mode', () {
      final system = HexEdgeRenderSystem(hexEdgeMeshCaste: meshCaste);

      final mesh = HexEdgeMesh.create(maxEdges: 5, isFlatTopped: true, hexSize: 10.0);

      // Batch 1: Red lines, width 1.0
      mesh.addEdge(0, 0, 1, 0, 0xFFFF0000, 1.0);
      mesh.addEdge(1, 0, 2, 0, 0xFFFF0000, 1.0);

      // Batch 2: Blue lines, width 2.0
      mesh.addEdge(2, 0, 3, 0, 0xFF0000FF, 2.0);

      meshCaste.add(1, mesh);

      final canvas = MockCanvas();
      system.render(canvas);

      // Should be two separate flushes because properties changed
      expect(canvas.drawRawPointsCalls, equals(2));

      // Verify last batch (Blue, width 2.0)
      expect(canvas.lastPointMode, equals(PointMode.lines));
      expect(canvas.lastPaint!.color.toARGB32(), equals(0xFF0000FF));
      expect(canvas.lastPaint!.strokeWidth, equals(2.0));

      // Last batch should contain 1 segment (4 floats)
      expect(canvas.lastPoints!.length, equals(4));
    });

    test('renders positional meshes considering world coordinates', () {
      final system = HexEdgeRenderSystem(
        hexEdgeMeshCaste: meshCaste,
        positionCaste: positionCaste,
      );

      final mesh = HexEdgeMesh.create(maxEdges: 1, isFlatTopped: false, hexSize: 10.0);
      mesh.addEdge(0, 0, 1, 0, 0xFFFFFFFF, 1.0);

      meshCaste.add(2, mesh);
      positionCaste.add(2, Position.create(100.0, 50.0));

      final canvas = MockCanvas();
      system.render(canvas);

      expect(canvas.drawRawPointsCalls, equals(1));

      // Points should be offset by the position (100.0, 50.0)
      final points = canvas.lastPoints!;
      final (hx1, hy1) = HexMath.pointyGridToWorld(0, 0, 10.0);
      final (hx2, hy2) = HexMath.pointyGridToWorld(1, 0, 10.0);

      expect(points[0], closeTo(100.0 + hx1, 0.001));
      expect(points[1], closeTo(50.0 + hy1, 0.001));
      expect(points[2], closeTo(100.0 + hx2, 0.001));
      expect(points[3], closeTo(50.0 + hy2, 0.001));
    });

    test('respects viewport transformations', () {
      final system = HexEdgeRenderSystem(
        hexEdgeMeshCaste: meshCaste,
        positionCaste: positionCaste,
        viewportCaste: viewportCaste,
        activeCameraEntity: 3,
      );

      final viewport = Viewport.create(10.0, 20.0, 2.0, 0.0);
      viewportCaste.add(3, viewport);

      final mesh = HexEdgeMesh.create(maxEdges: 1, isFlatTopped: true, hexSize: 10.0);
      mesh.addEdge(0, 0, 1, 0, 0xFFFFFFFF, 1.0);
      meshCaste.add(4, mesh);

      final canvas = MockCanvas();
      system.render(canvas);

      expect(canvas.saveCalls, equals(1));
      expect(canvas.scaleCalls, equals(1));
      expect(canvas.translateCalls, equals(1));
      expect(canvas.restoreCalls, equals(1));

      // Verify viewport applied to canvas
      expect(canvas.drawRawPointsCalls, equals(1));
    });

    test('does not throw exceptions when meshes are empty', () {
      final system = HexEdgeRenderSystem(hexEdgeMeshCaste: meshCaste);
      final mesh = HexEdgeMesh.create(maxEdges: 5, isFlatTopped: true, hexSize: 10.0);
      // Don't add edges
      meshCaste.add(1, mesh);

      final canvas = MockCanvas();
      system.render(canvas);

      expect(canvas.drawRawPointsCalls, equals(0));
    });
  });
}
