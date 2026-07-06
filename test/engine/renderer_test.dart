import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/renderer.dart';

void main() {
  group('Renderer', () {
    test('renderFrame does not throw', () {
      final renderer = Renderer();
      // Since PlatformDispatcher.instance.views might be empty in a test environment,
      // this call should simply return without throwing an error.
      expect(() => renderer.renderFrame(), returnsNormally);
    });

    test('calculateVirtualRect correctly computes rect without virtual size',
        () {
      final renderer = Renderer();
      final rect = renderer.calculateVirtualRect(const Size(800, 600));
      expect(rect, const Rect.fromLTWH(0, 0, 800, 600));
    });

    test(
        'calculateVirtualRect correctly computes rect with letterboxing (wider physical screen)',
        () {
      // Virtual resolution: 400x300 (aspect ratio 4:3)
      // Physical resolution: 1000x300 (aspect ratio 10:3, wider)
      // Expected scale: 1.0 (constrained by height)
      // Expected rect: 400x300 centered horizontally. offsetX = (1000 - 400)/2 = 300
      final renderer = Renderer(virtualWidth: 400, virtualHeight: 300);
      final rect = renderer.calculateVirtualRect(const Size(1000, 300));
      expect(rect, const Rect.fromLTWH(300, 0, 400, 300));
    });

    test(
        'calculateVirtualRect correctly computes rect with pillarboxing (taller physical screen)',
        () {
      // Virtual resolution: 400x300 (aspect ratio 4:3)
      // Physical resolution: 400x600 (aspect ratio 4:6, taller)
      // Expected scale: 1.0 (constrained by width)
      // Expected rect: 400x300 centered vertically. offsetY = (600 - 300)/2 = 150
      final renderer = Renderer(virtualWidth: 400, virtualHeight: 300);
      final rect = renderer.calculateVirtualRect(const Size(400, 600));
      expect(rect, const Rect.fromLTWH(0, 150, 400, 300));
    });

    test('calculateVirtualRect correctly computes rect with scaling', () {
      // Virtual resolution: 400x300
      // Physical resolution: 800x600 (scale 2.0 exactly)
      // Expected rect: 800x600 centered (offsetX=0, offsetY=0)
      final renderer = Renderer(virtualWidth: 400, virtualHeight: 300);
      final rect = renderer.calculateVirtualRect(const Size(800, 600));
      expect(rect, const Rect.fromLTWH(0, 0, 800, 600));
    });

    test('mapPointerX correctly maps X coordinate', () {
      // Virtual resolution: 400x300
      // Physical resolution: 1000x300 (offsetX=300, scale=1)
      final renderer = Renderer(virtualWidth: 400, virtualHeight: 300);
      final physicalSize = const Size(1000, 300);

      // Pointer exactly at the left edge of the virtual screen (physical X = 300)
      expect(renderer.mapPointerX(300, physicalSize), 0.0);

      // Pointer exactly at the right edge of the virtual screen (physical X = 700)
      expect(renderer.mapPointerX(700, physicalSize), 400.0);
    });

    test('mapPointerY correctly maps Y coordinate', () {
      // Virtual resolution: 400x300
      // Physical resolution: 400x600 (offsetY=150, scale=1)
      final renderer = Renderer(virtualWidth: 400, virtualHeight: 300);
      final physicalSize = const Size(400, 600);

      // Pointer exactly at the top edge of the virtual screen (physical Y = 150)
      expect(renderer.mapPointerY(150, physicalSize), 0.0);

      // Pointer exactly at the bottom edge of the virtual screen (physical Y = 450)
      expect(renderer.mapPointerY(450, physicalSize), 300.0);
    });

    test('mapPointer works correctly without virtual resolution', () {
      final renderer = Renderer();
      final physicalSize = const Size(800, 600);

      expect(renderer.mapPointerX(100, physicalSize), 100.0);
      expect(renderer.mapPointerY(200, physicalSize), 200.0);
    });
  });
}
