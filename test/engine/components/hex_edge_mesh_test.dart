import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/hex_edge_mesh.dart';

void main() {
  group('HexEdgeMesh', () {
    test('Initialization sets correct header values and array size', () {
      final mesh = HexEdgeMesh.create(
        maxEdges: 10,
        isFlatTopped: true,
        hexSize: 32.0,
      );

      expect(mesh.maxEdges, 10);
      expect(mesh.edgeCount, 0);
      expect(mesh.isFlatTopped, 1);
      expect(mesh.hexSize, closeTo(32.0, 0.001));

      // Header size is 4, edge stride is 6.
      // Total length = 4 + 10 * 6 = 64
      expect(mesh.data.length, 64);
      expect(mesh.data, isA<Float32List>());
    });

    test('Adding edges updates edge count and retrieves correctly', () {
      final mesh = HexEdgeMesh.create(
        maxEdges: 2,
        isFlatTopped: false,
        hexSize: 16.0,
      );

      // Add first edge
      final bool added1 = mesh.addEdge(0, 0, 1, -1, 0xFFFF0000, 2.5);
      expect(added1, isTrue);
      expect(mesh.edgeCount, 1);

      // Add second edge
      final bool added2 = mesh.addEdge(1, -1, 2, -2, 0xFF00FF00, 1.0);
      expect(added2, isTrue);
      expect(mesh.edgeCount, 2);

      // Try adding third edge (should fail due to max capacity)
      final bool added3 = mesh.addEdge(2, -2, 3, -3, 0xFF0000FF, 5.0);
      expect(added3, isFalse);
      expect(mesh.edgeCount, 2);

      // Verify retrieved edges
      final (q1_0, r1_0, q2_0, r2_0, color_0, width_0) = mesh.getEdge(0);
      expect(q1_0, 0);
      expect(r1_0, 0);
      expect(q2_0, 1);
      expect(r2_0, -1);
      expect(color_0, 0xFFFF0000);
      expect(width_0, closeTo(2.5, 0.001));

      final (q1_1, r1_1, q2_1, r2_1, color_1, width_1) = mesh.getEdge(1);
      expect(q1_1, 1);
      expect(r1_1, -1);
      expect(q2_1, 2);
      expect(r2_1, -2);
      expect(color_1, 0xFF00FF00);
      expect(width_1, closeTo(1.0, 0.001));
    });

    test('getEdge throws RangeError for invalid indices', () {
      final mesh = HexEdgeMesh.create(
        maxEdges: 5,
        isFlatTopped: true,
        hexSize: 10.0,
      );

      expect(() => mesh.getEdge(0), throwsRangeError);
      expect(() => mesh.getEdge(-1), throwsRangeError);

      mesh.addEdge(0, 0, 1, 0, 0xFFFFFFFF, 1.0);

      expect(() => mesh.getEdge(0), returnsNormally);
      expect(() => mesh.getEdge(1), throwsRangeError);
    });

    test('clear resets edge count without reallocating', () {
      final mesh = HexEdgeMesh.create(
        maxEdges: 5,
        isFlatTopped: true,
        hexSize: 10.0,
      );

      mesh.addEdge(0, 0, 1, 0, 0xFFFFFFFF, 1.0);
      expect(mesh.edgeCount, 1);

      mesh.clear();
      expect(mesh.edgeCount, 0);
      expect(mesh.data.length, 34); // 4 + 5 * 6

      // Can add again after clear
      mesh.addEdge(0, 0, -1, 0, 0x88888888, 2.0);
      expect(mesh.edgeCount, 1);
      final (_, _, q2, r2, color, width) = mesh.getEdge(0);
      expect(q2, -1);
      expect(r2, 0);
      expect(color, 0x88888888);
      expect(width, closeTo(2.0, 0.001));
    });
  });
}
