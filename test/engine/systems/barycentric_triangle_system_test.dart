import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/barycentric_triangle.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/barycentric_triangle_system.dart';

void main() {
  group('BarycentricTriangleSystem Tests', () {
    late ComponentStorage<BarycentricTriangle> storage;
    late BarycentricTriangleSystem system;
    late BarycentricTriangle tri;

    setUp(() {
      storage = ComponentStorage<BarycentricTriangle>(10);
      system = BarycentricTriangleSystem(storage);

      tri = BarycentricTriangle.create(
        centerX: 100.0,
        centerY: 100.0,
        radius: 100.0,
      );
      storage.add(1, tri);
    });

    test('Hit testing inside radius', () {
      final hitInside = system.handlePointerDown(100.0, 100.0); // Exactly center
      expect(hitInside, isTrue);
      expect(tri.isDragging, 1.0);

      // Release
      system.handlePointerUp(100.0, 100.0);
      expect(tri.isDragging, 0.0);
    });

    test('Hit testing outside radius', () {
      final hitOutside = system.handlePointerDown(300.0, 300.0); // Far away
      expect(hitOutside, isFalse);
      expect(tri.isDragging, 0.0);
    });

    test('Barycentric weights sum to 1 and within limits (Inside Triangle)', () {
      // Down on center
      system.handlePointerDown(100.0, 100.0);
      
      expect(tri.weightA + tri.weightB + tri.weightC, closeTo(1.0, 0.0001));
      expect(tri.weightA, closeTo(0.3333333, 0.0001));
      expect(tri.weightB, closeTo(0.3333333, 0.0001));
      expect(tri.weightC, closeTo(0.3333333, 0.0001));
    });

    test('Barycentric clamping to Corner A', () {
      // Corner A is at (0, -radius) relative to center, so (100, 0)
      system.handlePointerDown(100.0, 100.0); // Grab inside
      system.handlePointerMove(100.0, -50.0); // Drag way above top corner

      expect(tri.weightA + tri.weightB + tri.weightC, closeTo(1.0, 0.0001));
      expect(tri.weightA, closeTo(1.0, 0.0001));
      expect(tri.weightB, closeTo(0.0, 0.0001));
      expect(tri.weightC, closeTo(0.0, 0.0001));

      // Puck position should clamp to corner A absolute
      expect(tri.puckX, closeTo(100.0, 0.0001));
      expect(tri.puckY, closeTo(0.0, 0.0001)); 
    });

    test('Barycentric clamping to Corner B', () {
      // Corner B is at (radius * cos(pi/6), radius * sin(pi/6)) 
      // (100 + 86.602, 100 + 50) = (186.602, 150)
      system.handlePointerDown(100.0, 100.0); // Grab inside
      system.handlePointerMove(250.0, 200.0); // Drag way outside bottom right

      expect(tri.weightA + tri.weightB + tri.weightC, closeTo(1.0, 0.0001));
      expect(tri.weightA, closeTo(0.0, 0.0001));
      expect(tri.weightB, closeTo(1.0, 0.0001));
      expect(tri.weightC, closeTo(0.0, 0.0001));

      expect(tri.puckX, closeTo(100.0 + 100.0 * cos(pi / 6), 0.0001));
      expect(tri.puckY, closeTo(100.0 + 100.0 * sin(pi / 6), 0.0001)); 
    });

    test('Barycentric clamping to Corner C', () {
      // Corner C is at (-radius * cos(pi/6), radius * sin(pi/6))
      // (100 - 86.602, 100 + 50) = (13.397, 150)
      system.handlePointerDown(100.0, 100.0); // Grab inside
      system.handlePointerMove(-50.0, 200.0); // Drag way outside bottom left

      expect(tri.weightA + tri.weightB + tri.weightC, closeTo(1.0, 0.0001));
      expect(tri.weightA, closeTo(0.0, 0.0001));
      expect(tri.weightB, closeTo(0.0, 0.0001));
      expect(tri.weightC, closeTo(1.0, 0.0001));

      expect(tri.puckX, closeTo(100.0 - 100.0 * cos(pi / 6), 0.0001));
      expect(tri.puckY, closeTo(100.0 + 100.0 * sin(pi / 6), 0.0001)); 
    });

    test('Barycentric clamping to Edge BC', () {
      // Directly below the center, should clamp to bottom edge
      // The edge is horizontal between B and C at Y = 100 + 50 = 150
      system.handlePointerDown(100.0, 100.0); // Grab inside
      system.handlePointerMove(100.0, 300.0); // Drag outside bottom edge

      expect(tri.weightA + tri.weightB + tri.weightC, closeTo(1.0, 0.0001));
      expect(tri.weightA, closeTo(0.0, 0.0001)); // It's strictly on edge BC
      expect(tri.weightB, closeTo(0.5, 0.0001)); // Centered horizontally
      expect(tri.weightC, closeTo(0.5, 0.0001)); // Centered horizontally

      expect(tri.puckX, closeTo(100.0, 0.0001));
      expect(tri.puckY, closeTo(150.0, 0.0001)); 
    });

    test('Barycentric clamping to Edge CA', () {
      // Edge CA goes from C (-86.602, 150) to A (100, 0)
      // Point (0, 75) is outside Edge CA.
      system.handlePointerDown(100.0, 100.0); // Grab inside
      system.handlePointerMove(0.0, 75.0); 
      
      expect(tri.weightA + tri.weightB + tri.weightC, closeTo(1.0, 0.0001));
      expect(tri.weightB, closeTo(0.0, 0.0001));
      expect(tri.weightA, closeTo(0.336324, 0.0001));
      expect(tri.weightC, closeTo(0.663675, 0.0001));
    });

    test('Barycentric clamping to Edge AB', () {
      // Edge AB goes from A (100, 0) to B (186.602, 150)
      // Point (200, 75) is outside Edge AB.
      system.handlePointerDown(100.0, 100.0); // Grab inside
      system.handlePointerMove(200.0, 75.0); 
      
      expect(tri.weightA + tri.weightB + tri.weightC, closeTo(1.0, 0.0001));
      expect(tri.weightC, closeTo(0.0, 0.0001));
      expect(tri.weightA, closeTo(0.336324, 0.0001));
      expect(tri.weightB, closeTo(0.663675, 0.0001));
    });

    test('Pointer move updates dragged triangle', () {
      system.handlePointerDown(100.0, 100.0); // Grab center
      expect(tri.isDragging, 1.0);

      system.handlePointerMove(100.0, 0.0); // Drag up to Corner A
      
      expect(tri.weightA, closeTo(1.0, 0.0001));
      expect(tri.puckY, closeTo(0.0, 0.0001));
    });

    test('Pointer move does not update if not dragging', () {
      // Triangle weights start at 1/3
      expect(tri.weightA, closeTo(0.3333333, 0.0001));
      
      system.handlePointerMove(100.0, 0.0); // Move pointer without down event

      // Should remain unchanged
      expect(tri.weightA, closeTo(0.3333333, 0.0001));
    });

    test('handlePointerUp stops dragging', () {
      system.handlePointerDown(100.0, 100.0);
      expect(tri.isDragging, 1.0);

      system.handlePointerUp(100.0, 100.0);
      expect(tri.isDragging, 0.0);
    });
  });
}
