import 'dart:math';

/// A collection of easing functions for tweens.
/// Easing functions take a normalized time value [t] between 0.0 and 1.0
/// and return an eased value, usually between 0.0 and 1.0.
class Easing {
  /// Linear easing, no acceleration or deceleration.
  static double linear(double t) {
    return t;
  }

  /// Accelerating from zero velocity.
  static double easeInQuad(double t) {
    return t * t;
  }

  /// Decelerating to zero velocity.
  static double easeOutQuad(double t) {
    return t * (2 - t);
  }

  /// Acceleration until halfway, then deceleration.
  static double easeInOutQuad(double t) {
    if (t < 0.5) return 2 * t * t;
    return -1 + (4 - 2 * t) * t;
  }

  /// Accelerating from zero velocity.
  static double easeInCubic(double t) {
    return t * t * t;
  }

  /// Decelerating to zero velocity.
  static double easeOutCubic(double t) {
    t--;
    return t * t * t + 1;
  }

  /// Bouncing effect at the end.
  static double easeOutBounce(double t) {
    const n1 = 7.5625;
    const d1 = 2.75;

    if (t < 1 / d1) {
      return n1 * t * t;
    } else if (t < 2 / d1) {
      t -= 1.5 / d1;
      return n1 * t * t + 0.75;
    } else if (t < 2.5 / d1) {
      t -= 2.25 / d1;
      return n1 * t * t + 0.9375;
    } else {
      t -= 2.625 / d1;
      return n1 * t * t + 0.984375;
    }
  }

  /// Elastic effect at the end.
  static double easeOutElastic(double t) {
    if (t == 0.0) return 0.0;
    if (t == 1.0) return 1.0;

    const c4 = (2 * pi) / 0.3;
    return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1.0;
  }
}
