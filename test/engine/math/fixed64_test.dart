import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/math/fixed64.dart';
import 'dart:math' as math;

void main() {
  group('Fixed64', () {
    test('Conversions from/to double', () {
      final a = Fixed64.fromDouble(2.5);
      expect(a.toDouble(), 2.5);

      final b = Fixed64.fromDouble(-1.25);
      expect(b.toDouble(), -1.25);

      final zero = Fixed64.fromDouble(0.0);
      expect(zero.toDouble(), 0.0);
    });

    test('Conversions from/to int', () {
      final a = Fixed64.fromInt(5);
      expect(a.toInt(), 5);

      final b = Fixed64.fromInt(-3);
      expect(b.toInt(), -3);

      final zero = Fixed64.fromInt(0);
      expect(zero.toInt(), 0);
    });

    test('Addition', () {
      final a = Fixed64.fromDouble(1.5);
      final b = Fixed64.fromDouble(2.25);
      final c = a + b;
      expect(c.toDouble(), 3.75);
    });

    test('Subtraction', () {
      final a = Fixed64.fromDouble(5.0);
      final b = Fixed64.fromDouble(1.25);
      final c = a - b;
      expect(c.toDouble(), 3.75);

      final neg = -a;
      expect(neg.toDouble(), -5.0);
    });

    test('Multiplication', () {
      final a = Fixed64.fromDouble(1.5);
      final b = Fixed64.fromDouble(2.5);
      final c = a * b;
      expect(c.toDouble(), 3.75);

      final neg = Fixed64.fromDouble(-2.0);
      expect((a * neg).toDouble(), -3.0);

      final zero = Fixed64.zero;
      expect((a * zero).toDouble(), 0.0);
    });

    test('Division', () {
      final a = Fixed64.fromDouble(5.0);
      final b = Fixed64.fromDouble(2.0);
      final c = a / b;
      expect(c.toDouble(), 2.5);

      final d = Fixed64.fromDouble(1.0);
      final e = Fixed64.fromDouble(3.0);
      final f = d / e;
      expect(f.toDouble(), closeTo(0.33333333, 0.0000001));

      final neg = Fixed64.fromDouble(-2.0);
      expect((a / neg).toDouble(), -2.5);

      expect(() => a / Fixed64.zero, throwsArgumentError);
    });

    test('abs', () {
      expect(Fixed64.fromDouble(-5.25).abs().toDouble(), 5.25);
      expect(Fixed64.fromDouble(5.25).abs().toDouble(), 5.25);
      expect(Fixed64.zero.abs().toDouble(), 0.0);
    });

    test('clamp', () {
      final minVal = Fixed64.fromDouble(1.0);
      final maxVal = Fixed64.fromDouble(5.0);

      expect(Fixed64.fromDouble(3.0).clamp(minVal, maxVal).toDouble(), 3.0);
      expect(Fixed64.fromDouble(0.0).clamp(minVal, maxVal).toDouble(), 1.0);
      expect(Fixed64.fromDouble(6.0).clamp(minVal, maxVal).toDouble(), 5.0);
    });

    test('sqrt', () {
      expect(Fixed64.fromDouble(4.0).sqrt().toDouble(), 2.0);
      expect(Fixed64.fromDouble(9.0).sqrt().toDouble(), 3.0);
      expect(Fixed64.fromDouble(2.0).sqrt().toDouble(), closeTo(1.41421356, 0.0000001));
      expect(Fixed64.zero.sqrt().toDouble(), 0.0);

      expect(() => Fixed64.fromDouble(-1.0).sqrt(), throwsArgumentError);
    });

    test('Trigonometry: sin & cos', () {
      expect(Fixed64.zero.sin().toDouble(), 0.0);
      expect(Fixed64.zero.cos().toDouble(), closeTo(1.0, 0.001));

      expect(Fixed64.pi.sin().toDouble(), closeTo(0.0, 0.001));
      expect(Fixed64.pi.cos().toDouble(), closeTo(-1.0, 0.001));

      expect(Fixed64.halfPi.sin().toDouble(), closeTo(1.0, 0.001));
      expect(Fixed64.halfPi.cos().toDouble(), closeTo(0.0, 0.001));

      // Test reduction
      final x = Fixed64.twoPi + Fixed64.halfPi;
      expect(x.sin().toDouble(), closeTo(1.0, 0.001));

      // Test negative reduction
      final y = Fixed64.fromDouble(-math.pi / 2.0);
      final z = Fixed64.fromDouble(-math.pi * 1.5);
      expect(z.sin().toDouble(), closeTo(1.0, 0.001));
      expect(y.sin().toDouble(), closeTo(-1.0, 0.001));
    });

    test('Comparison operators', () {
      final a = Fixed64.fromDouble(2.0);
      final b = Fixed64.fromDouble(3.0);
      final c = Fixed64.fromDouble(2.0);

      expect(b > a, isTrue);
      expect(a > b, isFalse);

      expect(a < b, isTrue);
      expect(b < a, isFalse);

      expect(a >= c, isTrue);
      expect(b >= a, isTrue);
      expect(a >= b, isFalse);

      expect(a <= c, isTrue);
      expect(a <= b, isTrue);
      expect(b <= a, isFalse);
    });
  });

  group('FixedVec2', () {
    test('Creation and getters', () {
      final v = FixedVec2.fromValues(Fixed64.fromDouble(1.5), Fixed64.fromDouble(2.5));
      expect(v.x.toDouble(), 1.5);
      expect(v.y.toDouble(), 2.5);
    });

    test('Vector arithmetic', () {
      final v1 = FixedVec2.fromValues(Fixed64.fromDouble(1.0), Fixed64.fromDouble(2.0));
      final v2 = FixedVec2.fromValues(Fixed64.fromDouble(3.0), Fixed64.fromDouble(4.0));

      final vSum = v1 + v2;
      expect(vSum.x.toDouble(), 4.0);
      expect(vSum.y.toDouble(), 6.0);

      final vDiff = v2 - v1;
      expect(vDiff.x.toDouble(), 2.0);
      expect(vDiff.y.toDouble(), 2.0);
    });

    test('Zero allocation constraint (Record validation)', () {
      final v = FixedVec2((Fixed64.fromInt(10), Fixed64.fromInt(20)));

      expect(v.x.toInt(), 10);
      expect(v.y.toInt(), 20);
    });
  });
}
