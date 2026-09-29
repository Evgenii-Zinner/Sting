import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/sting.dart';

void main() {
  group('HeightMap Component', () {
    test('flat array initialization and metadata accessors', () {
      final hm = HeightMap.create(
        columns: 4,
        rows: 3,
        originX: 10.0,
        originY: 20.0,
        cellWidth: 2.0,
        cellHeight: 3.0,
        defaultHeight: 5.0,
      );

      expect(hm.columns, 4.0);
      expect(hm.rows, 3.0);
      expect(hm.originX, 10.0);
      expect(hm.originY, 20.0);
      expect(hm.cellWidth, 2.0);
      expect(hm.cellHeight, 3.0);
      expect(hm.minHeight, 5.0);
      expect(hm.maxHeight, 5.0);

      // Verify all elements are default height
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 4; c++) {
          expect(hm.getElevationAtCell(c, r), 5.0);
        }
      }
    });

    test('discrete cell accessors and bounds clamping', () {
      final hm = HeightMap.create(columns: 2, rows: 2);
      hm.setElevationAtCell(0, 0, 1.0);
      hm.setElevationAtCell(1, 0, 2.0);
      hm.setElevationAtCell(0, 1, 3.0);
      hm.setElevationAtCell(1, 1, 4.0);

      expect(hm.getElevationAtCell(0, 0), 1.0);
      expect(hm.getElevationAtCell(1, 0), 2.0);
      expect(hm.getElevationAtCell(0, 1), 3.0);
      expect(hm.getElevationAtCell(1, 1), 4.0);

      // Out of bounds get clamping
      expect(hm.getElevationAtCell(-1, -1), 1.0);
      expect(hm.getElevationAtCell(2, 2), 4.0);
      expect(hm.getElevationAtCell(-1, 0), 1.0);
      expect(hm.getElevationAtCell(0, -1), 1.0);

      // Out of bounds set is ignored
      hm.setElevationAtCell(-1, -1, 99.0);
      expect(hm.getElevationAtCell(0, 0), 1.0);
    });

    test('continuous bilinear interpolation', () {
      final hm = HeightMap.create(
        columns: 2,
        rows: 2,
        originX: 0.0,
        originY: 0.0,
        cellWidth: 1.0,
        cellHeight: 1.0,
      );

      hm.setElevationAtCell(0, 0, 0.0);
      hm.setElevationAtCell(1, 0, 10.0);
      hm.setElevationAtCell(0, 1, 10.0);
      hm.setElevationAtCell(1, 1, 20.0);

      // Corners
      expect(hm.sampleHeight(0.0, 0.0), closeTo(0.0, 0.0001));
      expect(hm.sampleHeight(1.0, 0.0), closeTo(10.0, 0.0001));
      expect(hm.sampleHeight(0.0, 1.0), closeTo(10.0, 0.0001));
      expect(hm.sampleHeight(1.0, 1.0), closeTo(20.0, 0.0001));

      // Edges
      expect(hm.sampleHeight(0.5, 0.0), closeTo(5.0, 0.0001));
      expect(hm.sampleHeight(0.0, 0.5), closeTo(5.0, 0.0001));

      // Center
      expect(hm.sampleHeight(0.5, 0.5), closeTo(10.0, 0.0001));

      // Off-center
      expect(hm.sampleHeight(0.75, 0.25), closeTo(10.0, 0.0001)); // (0.25*0 + 0.75*10)*0.75 + (0.25*10 + 0.75*20)*0.25 -> 7.5*0.75 + 17.5*0.25 = 5.625 + 4.375 = 10.0
    });

    test('analytical gradient calculation against known mathematical slopes', () {
      final hm = HeightMap.create(
        columns: 3,
        rows: 3,
        originX: 0.0,
        originY: 0.0,
        cellWidth: 2.0,
        cellHeight: 2.0,
      );

      // Create a planar incline: z = 3x + 4y
      hm.fillFromFunction((x, y) => 3.0 * x + 4.0 * y);

      // Given z = 3x + 4y, gradient is (3, 4) everywhere.
      final (gx1, gy1) = hm.sampleGradient(1.0, 1.0);
      expect(gx1, closeTo(3.0, 0.0001));
      expect(gy1, closeTo(4.0, 0.0001));

      final (gx2, gy2) = hm.sampleGradient(3.0, 3.0);
      expect(gx2, closeTo(3.0, 0.0001));
      expect(gy2, closeTo(4.0, 0.0001));

      // sampleGradientTo
      final out = Float32List(2);
      hm.sampleGradientTo(2.0, 2.0, out);
      expect(out[0], closeTo(3.0, 0.0001));
      expect(out[1], closeTo(4.0, 0.0001));
    });

    test('boundary clamping and out-of-bounds handling', () {
      final hm = HeightMap.create(
        columns: 2,
        rows: 2,
        originX: 10.0,
        originY: 10.0,
        cellWidth: 5.0,
        cellHeight: 5.0,
      );

      hm.setElevationAtCell(0, 0, 5.0);
      hm.setElevationAtCell(1, 0, 5.0);
      hm.setElevationAtCell(0, 1, 5.0);
      hm.setElevationAtCell(1, 1, 5.0);

      // Out of bounds samples should clamp to the edges
      expect(hm.sampleHeight(0.0, 0.0), closeTo(5.0, 0.0001));
      expect(hm.sampleHeight(100.0, 100.0), closeTo(5.0, 0.0001));

      // Gradient outside should be 0 since it clamps to the flat edges
      final (gx, gy) = hm.sampleGradient(-10.0, -10.0);
      expect(gx, closeTo(0.0, 0.0001));
      expect(gy, closeTo(0.0, 0.0001));
    });

    test('slope angle and surface normal calculations', () {
      final hm = HeightMap.create(
        columns: 2,
        rows: 2,
        originX: 0.0,
        originY: 0.0,
        cellWidth: 1.0,
        cellHeight: 1.0,
      );

      // z = 1x + 0y -> slope of 1 on X axis (45 degrees)
      hm.fillFromFunction((x, y) => x);

      double angle = hm.sampleSlopeAngle(0.5, 0.5);
      // steepness is atan(sqrt(1^2 + 0^2)) = atan(1) = 45 degrees = pi/4
      expect(angle, closeTo(pi / 4, 0.0001));

      final (nx, ny, nz) = hm.sampleNormal(0.5, 0.5);
      // n = (-gx, -gy, 1) normalized
      // (-1, 0, 1) -> length sqrt(2)
      // nx = -1 / sqrt(2) = -0.7071
      // ny = 0
      // nz = 1 / sqrt(2) = 0.7071
      expect(nx, closeTo(-1 / sqrt(2), 0.0001));
      expect(ny, closeTo(0.0, 0.0001));
      expect(nz, closeTo(1 / sqrt(2), 0.0001));
    });

    test('recalculateMinMax and fillFromFunction', () {
      final hm = HeightMap.create(columns: 3, rows: 3);

      hm.fillFromFunction((x, y) => x + y);

      // With origin 0, width 1, max col is 2, max row is 2
      // min = 0+0 = 0
      // max = 2+2 = 4
      expect(hm.minHeight, closeTo(0.0, 0.0001));
      expect(hm.maxHeight, closeTo(4.0, 0.0001));

      // Manually mess up some values
      hm.setElevationAtCell(0, 0, -10.0);
      hm.setElevationAtCell(2, 2, 20.0);

      // Before recalculation, min/max are old
      expect(hm.minHeight, closeTo(0.0, 0.0001));
      expect(hm.maxHeight, closeTo(4.0, 0.0001));

      hm.recalculateMinMax();

      // After recalculation
      expect(hm.minHeight, closeTo(-10.0, 0.0001));
      expect(hm.maxHeight, closeTo(20.0, 0.0001));
    });

    test('single cell height map', () {
      final hm = HeightMap.create(columns: 1, rows: 1, defaultHeight: 42.0);

      expect(hm.sampleHeight(0.0, 0.0), closeTo(42.0, 0.0001));
      expect(hm.sampleHeight(10.0, 10.0), closeTo(42.0, 0.0001));

      final (gx, gy) = hm.sampleGradient(0.0, 0.0);
      expect(gx, closeTo(0.0, 0.0001));
      expect(gy, closeTo(0.0, 0.0001));
    });
  });
}
