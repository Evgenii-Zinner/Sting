import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/hex_math.dart';

void main() {
  group('HexMath', () {
    test('hexDistance calculates correct distances', () {
      expect(HexMath.hexDistance(0, 0, 0, 0), 0);
      expect(HexMath.hexDistance(0, 0, 1, 0), 1);
      expect(HexMath.hexDistance(0, 0, 0, 1), 1);
      expect(HexMath.hexDistance(0, 0, -1, 1), 1);
      expect(HexMath.hexDistance(1, -1, -1, 1), 2);
      expect(HexMath.hexDistance(0, 0, 2, 2), 4);
    });

    test('pointyGridToWorld converts grid to correct world coordinates', () {
      const size = 10.0;
      final (x0, y0) = HexMath.pointyGridToWorld(0, 0, size);
      expect(x0, closeTo(0.0, 0.001));
      expect(y0, closeTo(0.0, 0.001));

      final (x1, y1) = HexMath.pointyGridToWorld(1, 0, size);
      expect(x1, closeTo(17.3205, 0.001)); // size * sqrt(3)
      expect(y1, closeTo(0.0, 0.001));

      final (x2, y2) = HexMath.pointyGridToWorld(0, 1, size);
      expect(x2, closeTo(8.6602, 0.001)); // size * sqrt(3) / 2
      expect(y2, closeTo(15.0, 0.001)); // size * 3 / 2
    });

    test('flatGridToWorld converts grid to correct world coordinates', () {
      const size = 10.0;
      final (x0, y0) = HexMath.flatGridToWorld(0, 0, size);
      expect(x0, closeTo(0.0, 0.001));
      expect(y0, closeTo(0.0, 0.001));

      final (x1, y1) = HexMath.flatGridToWorld(1, 0, size);
      expect(x1, closeTo(15.0, 0.001)); // size * 3 / 2
      expect(y1, closeTo(8.6602, 0.001)); // size * sqrt(3) / 2

      final (x2, y2) = HexMath.flatGridToWorld(0, 1, size);
      expect(x2, closeTo(0.0, 0.001));
      expect(y2, closeTo(17.3205, 0.001)); // size * sqrt(3)
    });

    test('pointyWorldToGrid converts world to correct grid coordinates', () {
      const size = 10.0;

      final (q0, r0) = HexMath.pointyWorldToGrid(0.0, 0.0, size);
      expect(q0, 0);
      expect(r0, 0);

      // Slightly off-center should round to the same hex
      final (q0b, r0b) = HexMath.pointyWorldToGrid(1.0, 1.0, size);
      expect(q0b, 0);
      expect(r0b, 0);

      final (x1, y1) = HexMath.pointyGridToWorld(1, 0, size);
      final (q1, r1) = HexMath.pointyWorldToGrid(x1, y1, size);
      expect(q1, 1);
      expect(r1, 0);

      final (x2, y2) = HexMath.pointyGridToWorld(2, -1, size);
      final (q2, r2) = HexMath.pointyWorldToGrid(x2, y2, size);
      expect(q2, 2);
      expect(r2, -1);
    });

    test('flatWorldToGrid converts world to correct grid coordinates', () {
      const size = 10.0;

      final (q0, r0) = HexMath.flatWorldToGrid(0.0, 0.0, size);
      expect(q0, 0);
      expect(r0, 0);

      // Slightly off-center should round to the same hex
      final (q0b, r0b) = HexMath.flatWorldToGrid(1.0, 1.0, size);
      expect(q0b, 0);
      expect(r0b, 0);

      final (x1, y1) = HexMath.flatGridToWorld(1, 0, size);
      final (q1, r1) = HexMath.flatWorldToGrid(x1, y1, size);
      expect(q1, 1);
      expect(r1, 0);

      final (x2, y2) = HexMath.flatGridToWorld(2, -1, size);
      final (q2, r2) = HexMath.flatWorldToGrid(x2, y2, size);
      expect(q2, 2);
      expect(r2, -1);
    });

    test('neighbor functions return correct relative and absolute coordinates', () {
      expect(HexMath.neighborDq(0), 1);
      expect(HexMath.neighborDr(0), 0);

      expect(HexMath.neighborDq(1), 1);
      expect(HexMath.neighborDr(1), -1);

      expect(HexMath.neighborDq(3), -1);
      expect(HexMath.neighborDr(3), 0);

      final (q1, r1) = HexMath.getNeighbor(5, 5, 0);
      expect(q1, 6);
      expect(r1, 5);

      final (q2, r2) = HexMath.getNeighbor(5, 5, 3);
      expect(q2, 4);
      expect(r2, 5);

      // Test wrap-around behavior if passing a direction >= 6 or < 0
      final (q3, r3) = HexMath.getNeighbor(0, 0, 6);
      expect(q3, 1);
      expect(r3, 0);
    });
  });
}
