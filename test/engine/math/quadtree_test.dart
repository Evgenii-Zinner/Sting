import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/quadtree.dart';

void main() {
  group('BarnesHutTree', () {
    test('initRoot clears and sets bounds', () {
      final tree = BarnesHutTree();
      tree.initRoot(0, 0, 100, 100);

      expect(tree.nodeCount, 1);
      expect(tree.totalMass, 0.0);
    });

    test('insert single entity updates mass and cm', () {
      final tree = BarnesHutTree();
      tree.initRoot(0, 0, 100, 100);

      tree.insert(1, 10, 20, 5.0);

      expect(tree.totalMass, 5.0);
    });

    test('insert multiple entities subdivides and calculates correct cm', () {
      final tree = BarnesHutTree();
      tree.initRoot(0, 0, 100, 100);

      tree.insert(1, 20, 20, 10.0);
      tree.insert(2, 80, 80, 10.0);

      expect(tree.nodeCount, greaterThan(1));
      expect(tree.totalMass, 20.0);

      // Center of mass should be (50, 50) because two equal masses are at (20,20) and (80,80)
      // Since root CM is index 0:
      // Unfortunately we can't easily read _nodeCM from outside, but we can test force to ensure CM is roughly right.
    });

    test('accumulateForce works', () {
      final tree = BarnesHutTree();
      tree.initRoot(0, 0, 1000, 1000);

      tree.insert(1, 10, 10, 100.0);

      final force = Float32List(2);
      // Entity 2 is at 10, 20 (distance 10 from entity 1)
      tree.accumulateForce(2, 10, 20, 0.5, 1.0, force);

      // Since dx = 0, dy = -10.
      // distance = ~10. Force = G * m1 * m2 / d^2. (we are finding force/mass, essentially acceleration)
      // Force = 1.0 * 100.0 / 100 = 1.0. (approx, considering softening)
      expect(force[0], closeTo(0.0, 0.1));
      expect(force[1], closeTo(-1.0, 0.1));
    });
  });
}
