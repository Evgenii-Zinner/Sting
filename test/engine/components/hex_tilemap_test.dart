import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/hex_tilemap.dart';

void main() {
  group('HexTilemap Component', () {
    test('should initialize with correct metadata and dimensions', () {
      final tilemap = HexTilemap.create(2, 1);

      expect(tilemap.radius, equals(2));
      expect(tilemap.isFlatTopped, equals(1));

      final diameter = 2 * 2 + 1; // 5
      expect(tilemap.diameter, equals(5));
      expect(tilemap.length, equals(25));

      // Underlying data should have length 2 + 25 = 27
      expect(tilemap.data.length, equals(27));
    });

    test('should get and set tiles correctly within bounds', () {
      final tilemap = HexTilemap.create(2, 0);

      // Initial tiles should be 0
      expect(tilemap.getTile(0, 0), equals(0));
      expect(tilemap.getTile(2, 2), equals(0));
      expect(tilemap.getTile(-2, -2), equals(0));

      // Set some tiles
      tilemap.setTile(0, 0, 1);
      tilemap.setTile(1, -1, 2);
      tilemap.setTile(-2, 2, 3);

      expect(tilemap.getTile(0, 0), equals(1));
      expect(tilemap.getTile(1, -1), equals(2));
      expect(tilemap.getTile(-2, 2), equals(3));
    });

    test('should handle out of bounds gracefully', () {
      final tilemap = HexTilemap.create(2, 0);

      // Getting out of bounds should return 0
      expect(tilemap.getTile(3, 0), equals(0));
      expect(tilemap.getTile(0, 3), equals(0));
      expect(tilemap.getTile(-3, 0), equals(0));
      expect(tilemap.getTile(0, -3), equals(0));

      // Setting out of bounds should not crash or modify anything
      tilemap.setTile(3, 0, 99);
      tilemap.setTile(-3, -3, 99);

      // Verify no changes happened to the center tile
      expect(tilemap.getTile(0, 0), equals(0));
    });

    test('should verify zero allocation structure', () {
      final tilemap = HexTilemap.create(1, 1);
      // Ensure the type is correctly an extension over Int32List
      expect(tilemap.data, isA<Int32List>());
    });
  });
}
