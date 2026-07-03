import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/mass.dart';
import 'package:sting/engine/ecs/component_caste.dart';

void main() {
  group('Mass Component', () {
    test('create initializes values correctly', () {
      final mass = Mass.create(10.5);

      expect(mass.value, 10.5);
      expect(mass.data, isA<Float32List>());
      expect(mass.data.length, 1);
    });

    test('getters and setters work correctly', () {
      final mass = Mass.create(0.0);

      mass.value = 42.0;

      expect(mass.value, 42.0);
      expect(mass.data[0], 42.0);
    });

    test('works with ComponentCaste', () {
      final caste = ComponentCaste<Mass>(100);
      final mass = Mass.create(5.0);

      caste.add(1, mass);

      final retrieved = caste.get(1);
      expect(retrieved, isNotNull);
      expect(retrieved!.value, 5.0);
    });
  });
}
