import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/isometric_math.dart';

void main() {
  group('IsometricMath', () {
    const double tileWidth = 64.0;
    const double tileHeight = 32.0;

    late Float32List outCoord;

    setUp(() {
      outCoord = Float32List(2);
    });

    group('Diamond Projection', () {
      test('isoToWorldDiamond should correctly convert col/row to world x/y',
          () {
        // Origin
        IsometricMath.isoToWorldDiamond(
            0.0, 0.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(0.0, 1e-5));
        expect(outCoord[1], closeTo(0.0, 1e-5));

        // (1, 0)
        IsometricMath.isoToWorldDiamond(
            1.0, 0.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(32.0, 1e-5));
        expect(outCoord[1], closeTo(16.0, 1e-5));

        // (0, 1)
        IsometricMath.isoToWorldDiamond(
            0.0, 1.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(-32.0, 1e-5));
        expect(outCoord[1], closeTo(16.0, 1e-5));

        // (1, 1)
        IsometricMath.isoToWorldDiamond(
            1.0, 1.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(0.0, 1e-5));
        expect(outCoord[1], closeTo(32.0, 1e-5));
      });

      test('worldToIsoDiamond should correctly convert world x/y to col/row',
          () {
        // Origin
        IsometricMath.worldToIsoDiamond(
            0.0, 0.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(0.0, 1e-5));
        expect(outCoord[1], closeTo(0.0, 1e-5));

        // (1, 0) equivalent
        IsometricMath.worldToIsoDiamond(
            32.0, 16.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(1.0, 1e-5));
        expect(outCoord[1], closeTo(0.0, 1e-5));

        // (0, 1) equivalent
        IsometricMath.worldToIsoDiamond(
            -32.0, 16.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(0.0, 1e-5));
        expect(outCoord[1], closeTo(1.0, 1e-5));

        // (1, 1) equivalent
        IsometricMath.worldToIsoDiamond(
            0.0, 32.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(1.0, 1e-5));
        expect(outCoord[1], closeTo(1.0, 1e-5));
      });

      test('Diamond projection is bidirectional', () {
        const testCases = [
          [2.5, 3.5],
          [-1.2, 4.8],
          [10.0, -5.0],
          [-7.3, -2.1]
        ];

        for (final tc in testCases) {
          final col = tc[0];
          final row = tc[1];

          IsometricMath.isoToWorldDiamond(
              col, row, tileWidth, tileHeight, outCoord);
          final wx = outCoord[0];
          final wy = outCoord[1];

          IsometricMath.worldToIsoDiamond(
              wx, wy, tileWidth, tileHeight, outCoord);
          expect(outCoord[0], closeTo(col, 1e-5));
          expect(outCoord[1], closeTo(row, 1e-5));
        }
      });
    });

    group('Staggered Projection', () {
      test('isoToWorldStaggered should correctly convert col/row to world x/y',
          () {
        // Origin (even row)
        IsometricMath.isoToWorldStaggered(
            0.0, 0.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(0.0, 1e-5));
        expect(outCoord[1], closeTo(0.0, 1e-5));

        // (1, 0) (even row)
        IsometricMath.isoToWorldStaggered(
            1.0, 0.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(64.0, 1e-5));
        expect(outCoord[1], closeTo(0.0, 1e-5));

        // (0, 1) (odd row -> shifted by half width)
        IsometricMath.isoToWorldStaggered(
            0.0, 1.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(32.0, 1e-5));
        expect(outCoord[1], closeTo(16.0, 1e-5));

        // (1, 1) (odd row -> shifted by half width)
        IsometricMath.isoToWorldStaggered(
            1.0, 1.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(96.0, 1e-5)); // 64 + 32
        expect(outCoord[1], closeTo(16.0, 1e-5));
      });

      test('worldToIsoStaggered should correctly convert world x/y to col/row',
          () {
        // Origin (even row)
        IsometricMath.worldToIsoStaggered(
            0.0, 0.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(0.0, 1e-5));
        expect(outCoord[1], closeTo(0.0, 1e-5));

        // (1, 0) equivalent
        IsometricMath.worldToIsoStaggered(
            64.0, 0.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(1.0, 1e-5));
        expect(outCoord[1], closeTo(0.0, 1e-5));

        // (0, 1) equivalent
        IsometricMath.worldToIsoStaggered(
            32.0, 16.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(0.0, 1e-5));
        expect(outCoord[1], closeTo(1.0, 1e-5));

        // (1, 1) equivalent
        IsometricMath.worldToIsoStaggered(
            96.0, 16.0, tileWidth, tileHeight, outCoord);
        expect(outCoord[0], closeTo(1.0, 1e-5));
        expect(outCoord[1], closeTo(1.0, 1e-5));
      });

      test('Staggered projection is bidirectional', () {
        const testCases = [
          [
            2.0,
            3.0
          ], // Integers required for stagger logic to be fully reversible without careful floor handling
          [-1.0, 4.0],
          [10.0, -5.0],
          [-7.0, -2.0],
          [0.5, 0.0], // Fractional col, even row
          [0.5, 1.0], // Fractional col, odd row
        ];

        for (final tc in testCases) {
          final col = tc[0];
          final row = tc[1];

          IsometricMath.isoToWorldStaggered(
              col, row, tileWidth, tileHeight, outCoord);
          final wx = outCoord[0];
          final wy = outCoord[1];

          IsometricMath.worldToIsoStaggered(
              wx, wy, tileWidth, tileHeight, outCoord);
          expect(outCoord[0], closeTo(col, 1e-5));
          expect(outCoord[1], closeTo(row, 1e-5));
        }
      });
    });

    group('getDepth', () {
      test('should calculate depth properly based on col + row', () {
        expect(IsometricMath.getDepth(0.0, 0.0), closeTo(0.0, 1e-5));
        expect(IsometricMath.getDepth(1.0, 0.0), closeTo(1.0, 1e-5));
        expect(IsometricMath.getDepth(0.0, 1.0), closeTo(1.0, 1e-5));
        expect(IsometricMath.getDepth(1.0, 1.0), closeTo(2.0, 1e-5));
        expect(IsometricMath.getDepth(-1.0, 2.5), closeTo(1.5, 1e-5));
      });
    });
  });
}
