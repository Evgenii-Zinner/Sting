import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/easing.dart';

void main() {
  group('Easing', () {
    test('linear', () {
      expect(Easing.linear(0.0), 0.0);
      expect(Easing.linear(0.5), 0.5);
      expect(Easing.linear(1.0), 1.0);
    });

    test('easeInQuad', () {
      expect(Easing.easeInQuad(0.0), 0.0);
      expect(Easing.easeInQuad(0.5), 0.25);
      expect(Easing.easeInQuad(1.0), 1.0);
    });

    test('easeOutQuad', () {
      expect(Easing.easeOutQuad(0.0), 0.0);
      expect(Easing.easeOutQuad(0.5), 0.75);
      expect(Easing.easeOutQuad(1.0), 1.0);
    });

    test('easeInOutQuad', () {
      expect(Easing.easeInOutQuad(0.0), 0.0);
      expect(Easing.easeInOutQuad(0.25), 0.125);
      expect(Easing.easeInOutQuad(0.5), 0.5);
      expect(Easing.easeInOutQuad(0.75), 0.875);
      expect(Easing.easeInOutQuad(1.0), 1.0);
    });

    test('easeInCubic', () {
      expect(Easing.easeInCubic(0.0), 0.0);
      expect(Easing.easeInCubic(0.5), 0.125);
      expect(Easing.easeInCubic(1.0), 1.0);
    });

    test('easeOutCubic', () {
      expect(Easing.easeOutCubic(0.0), 0.0);
      expect(Easing.easeOutCubic(0.5), 0.875);
      expect(Easing.easeOutCubic(1.0), 1.0);
    });

    test('easeOutBounce', () {
      expect(Easing.easeOutBounce(0.0), 0.0);
      expect(Easing.easeOutBounce(1.0), closeTo(1.0, 0.01));
    });

    test('easeOutElastic', () {
      expect(Easing.easeOutElastic(0.0), 0.0);
      expect(Easing.easeOutElastic(1.0), 1.0);
      // Ensure the elastic effect causes values slightly greater than 1
      bool hasOvershoot = false;
      for (double t = 0.1; t < 0.9; t += 0.1) {
        if (Easing.easeOutElastic(t) > 1.0) {
          hasOvershoot = true;
          break;
        }
      }
      expect(hasOvershoot, isTrue);
    });
  });
}
