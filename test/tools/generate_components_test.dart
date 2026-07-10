import 'package:flutter_test/flutter_test.dart';

// Import the actual generator script directly. This allows us to test its internal logic.
import '../../tools/generate_components.dart';

void main() {
  group('generate_components', () {
    test('generates Float32List schema correctly', () {
      final schema = {
        "name": "PositionTest",
        "type": "Float32List",
        "description": "A test float list component.",
        "fields": [
          {"name": "x"},
          {"name": "y"},
          {"name": "prevX", "init_from": "x"},
          {"name": "prevY", "init_from": "y"}
        ]
      };

      final code = generateComponentCode(schema);
      expect(code, contains('extension type PositionTest(Float32List data)'));
      expect(code, contains('PositionTest.create(double x, double y)'));
      expect(code, contains('..[0] = x'));
      expect(code, contains('..[1] = y'));
      expect(code, contains('..[2] = x'));
      expect(code, contains('..[3] = y'));
      expect(code, contains('double get x => data[0];'));
      expect(code, contains('set prevX(double value) => data[2] = value;'));
    });

    test('generates Int32List schema correctly', () {
      final schema = {
        "name": "Health",
        "type": "Int32List",
        "fields": [
          {"name": "current"},
          {"name": "max", "init_from": "current"}
        ]
      };

      final code = generateComponentCode(schema);
      expect(code, contains('extension type Health(Int32List data)'));
      expect(code, contains('Health.create(int current)'));
      expect(code, contains('..[0] = current'));
      expect(code, contains('..[1] = current'));
      expect(code, contains('int get max => data[1];'));
    });

    test('generates ByteData schema correctly', () {
      final schema = {
        "name": "MixedData",
        "type": "ByteData",
        "fields": [
          {"name": "id", "field_type": "Uint32"},
          {"name": "health", "field_type": "Float32"},
          {"name": "flags", "field_type": "Uint8"}
        ]
      };

      final code = generateComponentCode(schema);
      expect(code, contains('extension type MixedData(ByteData data)'));
      expect(code, contains('MixedData.create(int id, double health, int flags)'));
      expect(code, contains('..setUint32(0, id)'));
      expect(code, contains('..setFloat32(4, health)'));
      expect(code, contains('..setUint8(8, flags)'));
      expect(code, contains('int get id => data.getUint32(0);'));
      expect(code, contains('double get health => data.getFloat32(4);'));
      expect(code, contains('int get flags => data.getUint8(8);'));
      expect(code, contains('set flags(int value) => data.setUint8(8, value);'));
    });
  });
}
