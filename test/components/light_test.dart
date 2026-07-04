import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/light.dart';

void main() {
  group('Light Component', () {
    test('should initialize correctly via create', () {
      final light = Light.create(
        radius: 100.0,
        intensity: 0.8,
        r: 1.0,
        g: 0.5,
        b: 0.2,
        active: false,
      );

      expect(light.radius, 100.0);
      expect(light.intensity, closeTo(0.8, 0.001));
      expect(light.r, 1.0);
      expect(light.g, 0.5);
      expect(light.b, closeTo(0.2, 0.001));
      expect(light.active, false);
      expect(light.length, Light.componentSize);
    });

    test('should update properties correctly', () {
      final light = Light.create(radius: 50.0);
      expect(light.radius, 50.0);
      expect(light.intensity, 1.0);
      expect(light.active, true);

      light.radius = 200.0;
      light.intensity = 0.5;
      light.r = 0.1;
      light.active = false;

      expect(light.radius, 200.0);
      expect(light.intensity, 0.5);
      expect(light.r, closeTo(0.1, 0.001));
      expect(light.active, false);
    });
  });
}
