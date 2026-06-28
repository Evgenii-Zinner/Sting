import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/caste.dart';
import 'package:sting/engine/ecs/swarm.dart';

void main() {
  group('Caste (Sparse Set)', () {
    test('initializes correctly', () {
      final caste = Caste(100);
      expect(caste.length, 0);
    });

    test('throws if capacity is out of bounds', () {
      expect(() => Caste(-1), throwsArgumentError);
      expect(() => Caste(Swarm.maxEntities + 2), throwsArgumentError);
    });

    test('adds and contains entities', () {
      final caste = Caste(10);

      caste.add(5);
      expect(caste.contains(5), isTrue);
      expect(caste.length, 1);

      caste.add(100);
      expect(caste.contains(100), isTrue);
      expect(caste.length, 2);
    });

    test('adding an already existing entity does nothing', () {
      final caste = Caste(10);
      caste.add(5);
      expect(caste.length, 1);

      caste.add(5);
      expect(caste.length, 1);
    });

    test('throws RangeError when adding invalid entities', () {
      final caste = Caste(10);
      expect(() => caste.add(-1), throwsRangeError);
      expect(() => caste.add(Swarm.maxEntities + 1), throwsRangeError);
    });

    test('contains returns false for invalid entities', () {
      final caste = Caste(10);
      expect(caste.contains(-1), isFalse);
      expect(caste.contains(Swarm.maxEntities + 1), isFalse);
    });

    test('indexOf returns correct index and -1 for missing/invalid entities', () {
      final caste = Caste(10);
      caste.add(5);
      caste.add(15);

      expect(caste.indexOf(5), 0);
      expect(caste.indexOf(15), 1);

      expect(caste.indexOf(10), -1); // missing
      expect(caste.indexOf(-1), -1); // invalid
      expect(caste.indexOf(Swarm.maxEntities + 1), -1); // invalid
    });

    test('throws StateError when adding beyond capacity', () {
      final caste = Caste(2);
      caste.add(1);
      caste.add(2);

      expect(() => caste.add(3), throwsStateError);
    });

    test('removes entities correctly', () {
      final caste = Caste(10);
      caste.add(10);
      caste.add(20);
      caste.add(30);

      expect(caste.remove(20), isTrue);
      expect(caste.contains(20), isFalse);
      expect(caste.length, 2);

      // Ensure the dense array is contiguous by checking elements
      expect(caste.elementAt(0), 10);
      expect(caste.elementAt(1), 30); // 30 should have swapped into 20's place
    });

    test('removing non-existent entity returns false', () {
      final caste = Caste(10);
      caste.add(5);

      expect(caste.remove(10), isFalse);
      expect(caste.length, 1);
    });

    test('elementAt returns correct entities and throws on invalid index', () {
      final caste = Caste(10);
      caste.add(5);
      caste.add(15);

      expect(caste.elementAt(0), 5);
      expect(caste.elementAt(1), 15);

      expect(() => caste.elementAt(-1), throwsRangeError);
      expect(() => caste.elementAt(2), throwsRangeError);
    });

    test('clear resets the set in O(1)', () {
      final caste = Caste(10);
      caste.add(1);
      caste.add(2);
      caste.add(3);

      caste.clear();
      expect(caste.length, 0);
      expect(caste.contains(1), isFalse);
      expect(caste.contains(2), isFalse);
      expect(caste.contains(3), isFalse);

      // Re-adding should work
      caste.add(1);
      expect(caste.length, 1);
      expect(caste.contains(1), isTrue);
    });

    test('Briggs & Torczon validation ignores dirty memory after clear', () {
      final caste = Caste(10);
      caste.add(5); // index 0
      caste.clear();

      // Memory is "dirty", but validation should fail because count is 0
      expect(caste.contains(5), isFalse);
    });
  });
}
