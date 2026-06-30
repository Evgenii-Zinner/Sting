import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/time.dart';

void main() {
  group('Time', () {
    test('dt is 0.0 on the first update', () {
      final time = Time();
      expect(time.dt, 0.0);

      time.update(1000000); // 1 second
      expect(time.dt, 0.0);
    });

    test('calculates correct dt for normal frames', () {
      final time = Time();
      time.update(1000000); // Frame 1
      time.update(1016666); // Frame 2: ~16.6ms later (60fps)

      expect(time.dt, closeTo(0.016666, 0.000001));
    });

    test('caps dt at maxDt', () {
      final time = Time(maxDt: 0.1);
      time.update(1000000); // Frame 1

      // Simulate a 1 second lag spike
      time.update(2000000); // Frame 2

      // Should be capped at 0.1
      expect(time.dt, 0.1);
    });

    test('prevents negative dt if time goes backwards', () {
      final time = Time();
      time.update(2000000); // Frame 1

      // Time moves backwards
      time.update(1000000); // Frame 2

      expect(time.dt, 0.0);
    });

    test('accumulates time and consumes fixed steps', () {
      final time = Time(fixedDeltaTime: 1 / 60.0);
      time.update(1000000); // Initial frame

      // Simulate a 16.6ms update (1 frame at 60Hz)
      time.update(1000000 + (1000000 / 60).round());

      expect(time.consumeFixedStep(), isTrue);
      expect(time.consumeFixedStep(), isFalse); // Should only have 1 step

      // Simulate a 33.3ms update (2 frames at 60Hz)
      time.update(1000000 + (1000000 / 60).round() * 3);

      expect(time.consumeFixedStep(), isTrue);
      expect(time.consumeFixedStep(), isTrue);
      expect(time.consumeFixedStep(), isFalse);
    });
  });
}
