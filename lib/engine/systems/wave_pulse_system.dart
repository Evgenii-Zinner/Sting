import 'dart:math' as math;
import 'package:sting/engine/ecs/query.dart';
import 'package:sting/engine/components/wave_pulse.dart';

/// System responsible for updating and expanding WavePulse components.
class WavePulseSystem {
  final Query1<WavePulse> _wavePulses;

  WavePulseSystem(this._wavePulses);

  /// Updates all active wave pulses based on the delta time [dt].
  ///
  /// Enforces zero allocations per frame.
  void update(double dt) {
    _wavePulses.forEach((entity, pulse) {
      if (!pulse.isActive) return;

      // Expand the radius
      pulse.currentRadius += pulse.expansionSpeed * dt;

      // Check for max radius termination
      if (pulse.currentRadius >= pulse.maxRadius) {
        pulse.isActive = false;
        pulse.currentAmplitude = 0.0;
        return;
      }

      // Calculate new amplitude based on expansion and decay
      final ratio = pulse.currentRadius / pulse.maxRadius;
      final newAmplitude = pulse.initialAmplitude *
          (1.0 - ratio) *
          math.exp(-pulse.decayRate * ratio);

      pulse.currentAmplitude = newAmplitude;

      // Check for zero amplitude termination
      if (pulse.currentAmplitude <= 0.0) {
        pulse.isActive = false;
      }
    });
  }

  /// Evaluates the wave impulse at a target position.
  ///
  /// Iterates through all active wave pulses and returns the accumulated
  /// impulse as a pure unboxed Dart 3 record: (impulseX, impulseY, strength)
  /// with zero allocations.
  (double, double, double) evaluateWaveImpulse(double targetX, double targetY) {
    double totalImpulseX = 0.0;
    double totalImpulseY = 0.0;
    double totalStrength = 0.0;

    _wavePulses.forEach((entity, pulse) {
      if (!pulse.isActive) return;

      if (pulse.containsPoint(targetX, targetY)) {
        final dx = targetX - pulse.originX;
        final dy = targetY - pulse.originY;

        // Calculate unit vector direction, guarding against divide by zero
        final distanceSq = dx * dx + dy * dy;
        if (distanceSq > 0.000001) {
          final distance = math.sqrt(distanceSq);
          final dirX = dx / distance;
          final dirY = dy / distance;

          totalImpulseX += dirX * pulse.currentAmplitude;
          totalImpulseY += dirY * pulse.currentAmplitude;
          totalStrength += pulse.currentAmplitude;
        }
      }
    });

    return (totalImpulseX, totalImpulseY, totalStrength);
  }
}
