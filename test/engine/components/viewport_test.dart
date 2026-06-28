import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/ecs/component_caste.dart';

void main() {
  group('Viewport Component', () {
    test('creates with default values', () {
      final viewport = Viewport.create();
      expect(viewport.x, 0.0);
      expect(viewport.y, 0.0);
      expect(viewport.zoom, 1.0);
    });

    test('creates with custom values', () {
      final viewport = Viewport.create(10.5, 20.5, 2.0);
      expect(viewport.x, 10.5);
      expect(viewport.y, 20.5);
      expect(viewport.zoom, 2.0);
    });

    test('getters and setters work correctly', () {
      final viewport = Viewport.create();

      viewport.x = 100.0;
      viewport.y = -50.0;
      viewport.zoom = 0.5;

      expect(viewport.x, 100.0);
      expect(viewport.y, -50.0);
      expect(viewport.zoom, 0.5);
    });

    test('works with ComponentCaste', () {
      final caste = ComponentCaste<Viewport>(10);
      final viewport = Viewport.create(100, 200, 1.5);

      caste.add(1, viewport);

      final retrieved = caste.get(1);
      expect(retrieved, isNotNull);
      expect(retrieved!.x, 100);
      expect(retrieved.y, 200);
      expect(retrieved.zoom, 1.5);
    });
  });
}
