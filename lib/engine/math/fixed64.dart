

/// Q32.32 fixed-point numeric representation.
/// The higher 32 bits represent the integer part.
/// The lower 32 bits represent the fractional part.
extension type const Fixed64(int rawValue) {
  static const int _fractionBits = 32;
  static const double _multiplier = 4294967296.0; // 2^32
  static const double _divider = 1.0 / 4294967296.0; // 2^-32

  static const Fixed64 zero = Fixed64(0);
  static const Fixed64 one = Fixed64(1 << _fractionBits);
  static const Fixed64 pi = Fixed64(13493037704); // ~3.141592653589793 * 2^32
  static const Fixed64 twoPi = Fixed64(26986075409);
  static const Fixed64 halfPi = Fixed64(6746518852);

  // Conversion
  static Fixed64 fromDouble(double value) => Fixed64((value * _multiplier).round());
  double toDouble() => rawValue * _divider;

  static Fixed64 fromInt(int value) => Fixed64(value << _fractionBits);
  int toInt() => rawValue >> _fractionBits;

  // Operations
  Fixed64 operator +(Fixed64 other) => Fixed64(rawValue + other.rawValue);
  Fixed64 operator -(Fixed64 other) => Fixed64(rawValue - other.rawValue);
  Fixed64 operator -() => Fixed64(-rawValue);

  Fixed64 operator *(Fixed64 other) {
    int a = rawValue;
    int b = other.rawValue;

    int aHi = a >> 32;
    int aLo = a & 0xFFFFFFFF;
    int bHi = b >> 32;
    int bLo = b & 0xFFFFFFFF;

    int loLo = aLo * bLo;
    int loLoHi = loLo >> 32;
    int hiLo = aHi * bLo;
    int loHi = aLo * bHi;
    int hiHi = aHi * bHi;

    return Fixed64((hiHi << 32) + hiLo + loHi + loLoHi);
  }

  Fixed64 operator /(Fixed64 other) {
    int a = rawValue;
    int b = other.rawValue;
    if (b == 0) throw ArgumentError('Division by zero');

    int sign = 1;
    if (a < 0) {
      a = -a;
      sign = -sign;
    }
    if (b < 0) {
      b = -b;
      sign = -sign;
    }

    int quotient = a ~/ b;
    int remainder = a % b;
    int frac = 0;
    for (int i = 0; i < 32; i++) {
      remainder <<= 1;
      if (remainder >= b) {
        remainder -= b;
        frac |= (1 << (31 - i));
      }
    }

    return Fixed64(sign * ((quotient << 32) | frac));
  }

  Fixed64 abs() => rawValue < 0 ? Fixed64(-rawValue) : this;

  Fixed64 clamp(Fixed64 minVal, Fixed64 maxVal) {
    if (rawValue < minVal.rawValue) return minVal;
    if (rawValue > maxVal.rawValue) return maxVal;
    return this;
  }

  Fixed64 sqrt() {
    if (rawValue < 0) throw ArgumentError('Cannot calculate square root of a negative number');
    if (rawValue == 0) return Fixed64.zero;

    // Use Newton-Raphson method with fixed-point math to avoid BigInt allocation
    Fixed64 x = this;
    Fixed64 y = Fixed64.fromDouble(1.0); // Simple initial guess

    Fixed64 half = Fixed64(1 << 31); // 0.5 in Q32.32
    for (int i = 0; i < 24; i++) {
      Fixed64 nextY = (y + (x / y)) * half;
      if (nextY.rawValue == y.rawValue) break;
      y = nextY;
    }
    return y;
  }

  Fixed64 sin() {
    int x = rawValue;
    // Reduce to [-PI, PI]
    x = x.remainder(twoPi.rawValue);
    if (x > pi.rawValue) {
      x -= twoPi.rawValue;
    } else if (x < -pi.rawValue) {
      x += twoPi.rawValue;
    }

    Fixed64 val = Fixed64(x);
    Fixed64 x2 = val * val;
    Fixed64 x3 = x2 * val;
    Fixed64 x5 = x3 * x2;
    Fixed64 x7 = x5 * x2;
    Fixed64 x9 = x7 * x2;
    Fixed64 x11 = x9 * x2;

    Fixed64 term3 = x3 / Fixed64.fromInt(6);
    Fixed64 term5 = x5 / Fixed64.fromInt(120);
    Fixed64 term7 = x7 / Fixed64.fromInt(5040);
    Fixed64 term9 = x9 / Fixed64.fromInt(362880);
    Fixed64 term11 = x11 / Fixed64.fromInt(39916800);

    return val - term3 + term5 - term7 + term9 - term11;
  }

  Fixed64 cos() {
    return (this + halfPi).sin();
  }

  bool operator >(Fixed64 other) => rawValue > other.rawValue;
  bool operator <(Fixed64 other) => rawValue < other.rawValue;
  bool operator >=(Fixed64 other) => rawValue >= other.rawValue;
  bool operator <=(Fixed64 other) => rawValue <= other.rawValue;
}

/// Zero-allocation 2D vector utilizing Dart 3 Records and Fixed64 extension type.
extension type const FixedVec2((Fixed64, Fixed64) _data) {
  FixedVec2.fromValues(Fixed64 x, Fixed64 y) : _data = (x, y);

  Fixed64 get x => _data.$1;
  Fixed64 get y => _data.$2;

  FixedVec2 operator +(FixedVec2 other) => FixedVec2((x + other.x, y + other.y));
  FixedVec2 operator -(FixedVec2 other) => FixedVec2((x - other.x, y - other.y));
}
