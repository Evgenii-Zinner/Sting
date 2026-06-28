import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/ecs/swarm.dart';

void main() {
  group('ComponentCaste', () {
    test('initializes correctly', () {
      final caste = ComponentCaste<String>(100);
      expect(caste.length, 0);
    });

    test('adds and gets components', () {
      final caste = ComponentCaste<String>(10);

      caste.add(5, 'Player');
      expect(caste.length, 1);
      expect(caste.get(5), 'Player');

      caste.add(100, 'Enemy');
      expect(caste.length, 2);
      expect(caste.get(100), 'Enemy');
    });

    test('adding component to existing entity overwrites it', () {
      final caste = ComponentCaste<String>(10);
      caste.add(5, 'Player');
      expect(caste.get(5), 'Player');

      caste.add(5, 'SuperPlayer');
      expect(caste.length, 1);
      expect(caste.get(5), 'SuperPlayer');
    });

    test('getting component for invalid or missing entity returns null', () {
      final caste = ComponentCaste<String>(10);
      caste.add(5, 'Player');

      expect(caste.get(10), isNull);
      expect(caste.get(-1), isNull);
      expect(caste.get(Swarm.maxEntities + 1), isNull);
    });

    test('removes components and keeps dense array in sync', () {
      final caste = ComponentCaste<String>(10);
      caste.add(10, 'A'); // index 0
      caste.add(20, 'B'); // index 1
      caste.add(30, 'C'); // index 2

      expect(caste.remove(20), isTrue);
      expect(caste.length, 2);
      expect(caste.get(20), isNull);

      // Verify dense array swapping worked
      expect(caste.elementAt(0), 10);
      expect(caste.elementAt(1), 30); // 30 swapped into 20's place

      // Verify component swapping worked
      expect(caste.getComponentAt(0), 'A');
      expect(caste.getComponentAt(1), 'C'); // 'C' swapped into 'B's place
    });

    test('removing non-existent entity returns false', () {
      final caste = ComponentCaste<String>(10);
      caste.add(5, 'Player');

      expect(caste.remove(10), isFalse);
      expect(caste.length, 1);
    });

    test('clears the caste properly', () {
      final caste = ComponentCaste<String>(10);
      caste.add(1, 'A');
      caste.add(2, 'B');

      caste.clear();
      expect(caste.length, 0);
      expect(caste.get(1), isNull);
      expect(caste.get(2), isNull);
    });

    test('getComponentAt and elementAt throws RangeError for invalid index', () {
      final caste = ComponentCaste<String>(10);
      caste.add(5, 'Player');

      expect(() => caste.getComponentAt(-1), throwsRangeError);
      expect(() => caste.getComponentAt(1), throwsRangeError);

      expect(() => caste.elementAt(-1), throwsRangeError);
      expect(() => caste.elementAt(1), throwsRangeError);
    });
  });
}
