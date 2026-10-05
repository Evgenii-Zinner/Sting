import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/scalar_field_sampler.dart';

void main() {
  group('ScalarFieldSampler', () {
    late Float32List grid;
    final int cols = 3;
    final int rows = 3;

    setUp(() {
      // 10 20 30
      // 40 50 60
      // 70 80 90
      grid = Float32List.fromList([
        10, 20, 30,
        40, 50, 60,
        70, 80, 90,
      ]);
    });

    test('exact corner hits', () {
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 0.0, 0.0), 10.0);
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 1.0, 0.0), 20.0);
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 2.0, 0.0), 30.0);
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 0.0, 1.0), 40.0);
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 1.0, 1.0), 50.0);
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 2.0, 2.0), 90.0);
    });

    test('midpoint interpolation', () {
      // Halfway between (0,0)=10 and (1,0)=20
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 0.5, 0.0), 15.0);

      // Halfway between (0,0)=10 and (0,1)=40
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 0.0, 0.5), 25.0);

      // Center of top-left 2x2 square: (10+20+40+50)/4 = 30
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 0.5, 0.5), 30.0);

      // Center of middle 2x2 square (0.5 to 1.5, 0.5 to 1.5 is complicated, let's do 1.5, 1.5)
      // center of (1,1)=50, (2,1)=60, (1,2)=80, (2,2)=90
      // (50+60+80+90)/4 = 280/4 = 70
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 1.5, 1.5), 70.0);
    });

    test('out-of-bounds default value (zero padding)', () {
      // Just out of bounds left
      // -0.5, 0.0 -> x0=-1, x1=0. tx=0.5. c00=0, c10=10. lerp(0, 10, 0.5) = 5
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, -0.5, 0.0), 5.0);

      // Far out of bounds
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, -5.0, 0.0), 0.0);
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 0.0, -5.0), 0.0);
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 5.0, 5.0), 0.0);

      // Custom default value
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, -5.0, 0.0, defaultValue: 100.0), 100.0);
    });

    test('out-of-bounds clamping', () {
      // Clamp to top-left corner
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, -1.0, -1.0, clamp: true), 10.0);

      // Clamp to bottom-right corner
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 5.0, 5.0, clamp: true), 90.0);

      // Interpolate between clamped top edge and valid middle
      // y=-0.5, x=0. y0=-1, y1=0. ty=0.5. c00=10 (clamped), c01=10 (valid). lerp(10, 10, 0.5) = 10
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 0.0, -0.5, clamp: true), 10.0);

      // Interpolate past right edge
      // x=2.5, y=0. x0=2, x1=3. tx=0.5. c00=30, c10=30 (clamped). lerp(30,30,0.5)=30
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 2.5, 0.0, clamp: true), 30.0);
    });

    test('wrapping (toroidal)', () {
      // x=3.0 wrapped is x=0.0 -> 10.0
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 3.0, 0.0, wrap: true), 10.0);

      // x=-1.0 wrapped is x=2.0 -> 30.0
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, -1.0, 0.0, wrap: true), 30.0);

      // Interpolate between right edge and left edge
      // x=2.5, y=0. x0=2, x1=3(wrap 0). tx=0.5. c00=30, c10=10. lerp(30,10,0.5)=20
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 2.5, 0.0, wrap: true), 20.0);

      // Interpolate between bottom right and top left diagonally
      // x=2.5, y=2.5.
      // c00=(2,2)=90
      // c10=(3,2)->(0,2)=70
      // c01=(2,3)->(2,0)=30
      // c11=(3,3)->(0,0)=10
      // top = lerp(90, 70, 0.5) = 80
      // bot = lerp(30, 10, 0.5) = 20
      // res = lerp(80, 20, 0.5) = 50
      expect(ScalarFieldSampler.sampleBilinear(grid, cols, rows, 2.5, 2.5, wrap: true), 50.0);
    });
  });
}
