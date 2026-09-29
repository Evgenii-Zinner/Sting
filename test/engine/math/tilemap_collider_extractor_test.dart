import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/tilemap_collider_extractor.dart';

void main() {
  group('TilemapColliderExtractor', () {
    test('extractOrthogonalAABBs extracts single tile', () {
      final extractor = TilemapColliderExtractor(3, 3);
      final outBuffer = Float32List(16);

      // Solid tile at (1, 1)
      bool isSolid(int x, int y) => x == 1 && y == 1;

      final count =
          extractor.extractOrthogonalAABBs(10.0, 10.0, isSolid, outBuffer);

      expect(count, 4);
      expect(outBuffer.sublist(0, 4), [10.0, 10.0, 10.0, 10.0]); // x, y, w, h
    });

    test('extractOrthogonalAABBs merges horizontal line', () {
      final extractor = TilemapColliderExtractor(3, 3);
      final outBuffer = Float32List(16);

      // Solid tiles at (0, 0), (1, 0), (2, 0)
      bool isSolid(int x, int y) => y == 0;

      final count =
          extractor.extractOrthogonalAABBs(10.0, 10.0, isSolid, outBuffer);

      expect(count, 4);
      expect(outBuffer.sublist(0, 4), [0.0, 0.0, 30.0, 10.0]);
    });

    test('extractOrthogonalAABBs merges vertical line', () {
      final extractor = TilemapColliderExtractor(3, 3);
      final outBuffer = Float32List(16);

      // Solid tiles at (0, 0), (0, 1), (0, 2)
      bool isSolid(int x, int y) => x == 0;

      final count =
          extractor.extractOrthogonalAABBs(10.0, 10.0, isSolid, outBuffer);

      expect(count, 4);
      expect(outBuffer.sublist(0, 4), [0.0, 0.0, 10.0, 30.0]);
    });

    test('extractOrthogonalAABBs merges 2x2 block', () {
      final extractor = TilemapColliderExtractor(3, 3);
      final outBuffer = Float32List(16);

      // Solid tiles at (0, 0), (1, 0), (0, 1), (1, 1)
      bool isSolid(int x, int y) => x < 2 && y < 2;

      final count =
          extractor.extractOrthogonalAABBs(10.0, 10.0, isSolid, outBuffer);

      expect(count, 4);
      expect(outBuffer.sublist(0, 4), [0.0, 0.0, 20.0, 20.0]);
    });

    test('extractOrthogonalAABBs stops when buffer full', () {
      final extractor = TilemapColliderExtractor(3, 3);
      final outBuffer = Float32List(2); // Too small

      bool isSolid(int x, int y) => x == 0 && y == 0;

      final count =
          extractor.extractOrthogonalAABBs(10.0, 10.0, isSolid, outBuffer);

      expect(count, 0); // Didn't write anything
    });

    test('extractPolygons for orthogonal grid', () {
      final extractor = TilemapColliderExtractor(3, 3);
      final outBuffer = Float32List(16);

      // Solid tiles at (0, 0), (1, 0), (0, 1), (1, 1)
      bool isSolid(int x, int y) => x < 2 && y < 2;

      final count = extractor.extractPolygons(
          GridType.orthogonal, 10.0, 10.0, isSolid, outBuffer);

      expect(count, 8);
      // Top-left, Top-right, Bottom-right, Bottom-left
      expect(outBuffer.sublist(0, 8),
          [0.0, 0.0, 20.0, 0.0, 20.0, 20.0, 0.0, 20.0]);
    });

    test('extractPolygons for isometricDiamond grid', () {
      final extractor = TilemapColliderExtractor(3, 3);
      final outBuffer = Float32List(16);

      // Solid tiles at (0, 0), (1, 0), (0, 1), (1, 1)
      bool isSolid(int x, int y) => x < 2 && y < 2;

      final count = extractor.extractPolygons(
          GridType.isometricDiamond, 20.0, 10.0, isSolid, outBuffer);

      expect(count, 8);
      // Using IsometricMath.isoToWorldDiamond
      // 0, 0 -> 0.0, 0.0
      // 2, 0 -> 20.0, 10.0
      // 2, 2 -> 0.0, 20.0
      // 0, 2 -> -20.0, 10.0
      expect(outBuffer.sublist(0, 8),
          [0.0, 0.0, 20.0, 10.0, 0.0, 20.0, -20.0, 10.0]);
    });

    test('extractPolygons throws for isometricStaggered', () {
      final extractor = TilemapColliderExtractor(3, 3);
      final outBuffer = Float32List(16);

      bool isSolid(int x, int y) => true;

      expect(
          () => extractor.extractPolygons(
              GridType.isometricStaggered, 10.0, 10.0, isSolid, outBuffer),
          throwsArgumentError);
    });

    test('extractPolygons stops when buffer full', () {
      final extractor = TilemapColliderExtractor(3, 3);
      final outBuffer = Float32List(4); // Too small for 8 floats

      bool isSolid(int x, int y) => x == 0 && y == 0;

      final count = extractor.extractPolygons(
          GridType.orthogonal, 10.0, 10.0, isSolid, outBuffer);

      expect(count, 0); // Didn't write anything
    });
  });
}
