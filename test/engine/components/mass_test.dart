import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/mass.dart';
import 'package:sting/engine/ecs/component_caste.dart';

void main() {
  group('Mass Component', () {
    test('create initializes values correctly', () {
      final mass = Mass.create(10.0, restitution: 0.5, friction: 0.2);

      expect(mass.value, 10.0);
      expect(mass.inverseMass, closeTo(0.1, 1e-6));
      expect(mass.restitution, closeTo(0.5, 1e-6));
      expect(mass.friction, closeTo(0.2, 1e-6));
      expect(mass.data, isA<Float32List>());
      expect(mass.data.length, 4);
    });

    test('create handles infinite mass (0.0)', () {
      final mass = Mass.create(0.0);

      expect(mass.value, 0.0);
      expect(mass.inverseMass, 0.0);
    });

    test('getters and setters work correctly', () {
      final mass = Mass.create(0.0);

      mass.value = 40.0;
      mass.restitution = 0.8;
      mass.friction = 0.4;

      expect(mass.value, 40.0);
      expect(mass.inverseMass, closeTo(0.025, 1e-6));
      expect(mass.restitution, closeTo(0.8, 1e-6));
      expect(mass.friction, closeTo(0.4, 1e-6));

      expect(mass.data[0], 40.0);
      expect(mass.data[1], closeTo(0.025, 1e-6));
      expect(mass.data[2], closeTo(0.8, 1e-6));
      expect(mass.data[3], closeTo(0.4, 1e-6));
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
