import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/bounding_box.dart';

void main() {
  group('BoundingBox', () {
    test('creates and gets values correctly', () {
      final bbox = BoundingBox.create(10.5, 20.25);

      expect(bbox.width, 10.5);
      expect(bbox.height, 20.25);
    });

    test('sets values correctly', () {
      final bbox = BoundingBox.create(0.0, 0.0);

      bbox.width = 15.0;
      bbox.height = 30.0;

      expect(bbox.width, 15.0);
      expect(bbox.height, 30.0);
    });

    test('is backed by Float32List', () {
      final bbox = BoundingBox.create(5.0, 5.0);
      expect(bbox.data, isA<Float32List>());
      expect(bbox.data.length, 2);
    });
  });
}
