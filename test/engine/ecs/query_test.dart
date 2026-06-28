import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/query.dart';

void main() {
  group('Query1', () {
    test('forEach iterates over all components', () {
      final caste = ComponentCaste<String>(100);
      caste.add(1, 'A');
      caste.add(2, 'B');
      caste.add(3, 'C');

      final query = Query1(caste);

      final results = <int, String>{};
      query.forEach((entity, component) {
        results[entity] = component;
      });

      expect(results, {1: 'A', 2: 'B', 3: 'C'});
    });

    test('forEach handles empty caste', () {
      final caste = ComponentCaste<String>(100);
      final query = Query1(caste);

      int count = 0;
      query.forEach((entity, component) {
        count++;
      });

      expect(count, 0);
    });
  });

  group('Query2', () {
    test('forEach finds intersections correctly', () {
      final caste1 = ComponentCaste<String>(100);
      final caste2 = ComponentCaste<int>(100);

      // Entity 1 is in both
      caste1.add(1, 'A');
      caste2.add(1, 10);

      // Entity 2 is only in caste1
      caste1.add(2, 'B');

      // Entity 3 is only in caste2
      caste2.add(3, 30);

      // Entity 4 is in both
      caste1.add(4, 'D');
      caste2.add(4, 40);

      final query = Query2(caste1, caste2);

      final results = <int, Map<String, dynamic>>{};
      query.forEach((entity, comp1, comp2) {
        results[entity] = {'comp1': comp1, 'comp2': comp2};
      });

      expect(results.length, 2);
      expect(results[1], {'comp1': 'A', 'comp2': 10});
      expect(results[4], {'comp1': 'D', 'comp2': 40});
    });

    test('forEach handles no intersections', () {
      final caste1 = ComponentCaste<String>(100);
      final caste2 = ComponentCaste<int>(100);

      caste1.add(1, 'A');
      caste2.add(2, 20);

      final query = Query2(caste1, caste2);

      int count = 0;
      query.forEach((entity, comp1, comp2) {
        count++;
      });

      expect(count, 0);
    });

    test('forEach handles empty castes', () {
      final caste1 = ComponentCaste<String>(100);
      final caste2 = ComponentCaste<int>(100);

      final query = Query2(caste1, caste2);

      int count = 0;
      query.forEach((entity, comp1, comp2) {
        count++;
      });

      expect(count, 0);
    });

    test('forEach performs correctly when caste2 is smaller than caste1', () {
      final caste1 = ComponentCaste<String>(100);
      final caste2 = ComponentCaste<int>(100);

      caste1.add(1, 'A');
      caste1.add(2, 'B');
      caste1.add(3, 'C');
      caste1.add(4, 'D');

      caste2.add(2, 20);
      caste2.add(4, 40);

      final query = Query2(caste1, caste2);

      final results = <int, Map<String, dynamic>>{};
      query.forEach((entity, comp1, comp2) {
        results[entity] = {'comp1': comp1, 'comp2': comp2};
      });

      expect(results.length, 2);
      expect(results[2], {'comp1': 'B', 'comp2': 20});
      expect(results[4], {'comp1': 'D', 'comp2': 40});
    });
  });
}
