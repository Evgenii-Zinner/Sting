import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/virtual_joypad.dart';

void main() {
  group('VirtualJoypad Component', () {
    test('Initialization sets values correctly', () {
      final pad = VirtualJoypad.create(
        maxRadius: 50.0,
        centerX: 100.0,
        centerY: 150.0,
        knobEntityId: 2.0,
      );

      expect(pad.vectorX, 0.0);
      expect(pad.vectorY, 0.0);
      expect(pad.maxRadius, 50.0);
      expect(pad.centerX, 100.0);
      expect(pad.centerY, 150.0);
      expect(pad.knobEntityId, 2.0);
      expect(pad.activePointerId, -1.0);
    });

    test('Setters update values correctly', () {
      final pad = VirtualJoypad.create(
        maxRadius: 0.0,
        centerX: 0.0,
        centerY: 0.0,
      );

      pad.vectorX = 0.5;
      pad.vectorY = -0.5;
      pad.maxRadius = 100.0;
      pad.centerX = 200.0;
      pad.centerY = 250.0;
      pad.knobEntityId = 5.0;
      pad.activePointerId = 1.0;

      expect(pad.vectorX, 0.5);
      expect(pad.vectorY, -0.5);
      expect(pad.maxRadius, 100.0);
      expect(pad.centerX, 200.0);
      expect(pad.centerY, 250.0);
      expect(pad.knobEntityId, 5.0);
      expect(pad.activePointerId, 1.0);
    });
  });
}
