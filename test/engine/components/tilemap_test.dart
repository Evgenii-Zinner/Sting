import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/tilemap.dart';

void main() {
  group('Tilemap Component', () {
    test('should initialize with correct metadata and dimensions', () {
      final tilemap = Tilemap.create(10, 5, 16, 16);

      expect(tilemap.columns, equals(10));
      expect(tilemap.rows, equals(5));
      expect(tilemap.tileWidth, equals(16));
      expect(tilemap.tileHeight, equals(16));
      expect(tilemap.length, equals(50));

      // Underlying data should have length 4 + 50 = 54
      expect(tilemap.data.length, equals(54));
    });

    test('should get and set tiles correctly within bounds', () {
      final tilemap = Tilemap.create(10, 10, 32, 32);

      // Initial tiles should be 0
      expect(tilemap.getTile(0, 0), equals(0));
      expect(tilemap.getTile(9, 9), equals(0));

      // Set some tiles
      tilemap.setTile(0, 0, 1);
      tilemap.setTile(5, 5, 2);
      tilemap.setTile(9, 9, 3);

      expect(tilemap.getTile(0, 0), equals(1));
      expect(tilemap.getTile(5, 5), equals(2));
      expect(tilemap.getTile(9, 9), equals(3));

      // Verify underlying array directly
      expect(tilemap.data[4], equals(1)); // (0, 0) is at index 4
      expect(tilemap.data[4 + (5 * 10) + 5], equals(2)); // (5, 5)
      expect(tilemap.data[4 + (9 * 10) + 9], equals(3)); // (9, 9)
    });

    test('should handle out of bounds gracefully', () {
      final tilemap = Tilemap.create(5, 5, 16, 16);

      // Getting out of bounds should return 0
      expect(tilemap.getTile(-1, 0), equals(0));
      expect(tilemap.getTile(0, -1), equals(0));
      expect(tilemap.getTile(5, 0), equals(0));
      expect(tilemap.getTile(0, 5), equals(0));

      // Setting out of bounds should not crash or modify anything
      tilemap.setTile(-1, 0, 99);
      tilemap.setTile(5, 5, 99);

      // Verify no changes happened to the 0th tile
      expect(tilemap.getTile(0, 0), equals(0));
    });

    test('should verify zero allocation structure', () {
      final tilemap = Tilemap.create(2, 2, 8, 8);
      // Ensure the type is correctly an extension over Int32List
      expect(tilemap.data, isA<Int32List>());
    });
  });
}
