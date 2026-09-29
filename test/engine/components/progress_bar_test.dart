import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/progress_bar.dart';

void main() {
  group('ProgressBar Component', () {
    test('Initialization values are correct', () {
      final bar = ProgressBar.create();
      expect(bar.currentValue, 100.0);
      expect(bar.maxValue, 100.0);
      expect(bar.visualValue, 100.0);
      expect(bar.width, 100.0);
      expect(bar.height, 10.0);
      expect(bar.borderWidth, 1.0);
      expect(bar.borderRadius, 2.0);
      // Due to Float32 precision loss at >24 bits, these numbers are approximations
      expect(bar.fillColorHex, closeTo(0xFF00E5FF.toDouble(), 200.0));
      expect(bar.backgroundColorHex, closeTo(0xFF0A0C14.toDouble(), 200.0));
      expect(bar.borderColorHex, closeTo(0xFF00B0FF.toDouble(), 200.0));
      expect(bar.ghostColorHex, closeTo(0xFFFF5252.toDouble(), 200.0));
      expect(bar.segments, 0.0);
      expect(bar.isWorldSpace, 1.0);
      expect(bar.offsetX, 0.0);
      expect(bar.offsetY, 0.0);
      expect(bar.catchUpSpeed, 5.0);
    });

    test('Values can be read and updated', () {
      final bar = ProgressBar.create();
      bar.currentValue = 50.0;
      bar.maxValue = 200.0;
      bar.visualValue = 75.0;
      bar.width = 250.0;
      bar.height = 15.0;
      bar.borderWidth = 2.0;
      bar.borderRadius = 5.0;
      bar.fillColorHex = 0xFFFFFFFF.toDouble();
      bar.backgroundColorHex = 0xFF000000.toDouble();
      bar.borderColorHex = 0xFF111111.toDouble();
      bar.ghostColorHex = 0xFF222222.toDouble();
      bar.segments = 5.0;
      bar.isWorldSpace = 0.0;
      bar.offsetX = 10.0;
      bar.offsetY = 20.0;
      bar.catchUpSpeed = 10.0;

      expect(bar.currentValue, 50.0);
      expect(bar.maxValue, 200.0);
      expect(bar.visualValue, 75.0);
      expect(bar.width, 250.0);
      expect(bar.height, 15.0);
      expect(bar.borderWidth, 2.0);
      expect(bar.borderRadius, 5.0);
      expect(bar.fillColorHex, closeTo(0xFFFFFFFF.toDouble(), 200.0));
      expect(bar.backgroundColorHex, 0xFF000000.toDouble());
      expect(bar.borderColorHex, closeTo(0xFF111111.toDouble(), 200.0));
      expect(bar.ghostColorHex, closeTo(0xFF222222.toDouble(), 200.0));
      expect(bar.segments, 5.0);
      expect(bar.isWorldSpace, 0.0);
      expect(bar.offsetX, 10.0);
      expect(bar.offsetY, 20.0);
      expect(bar.catchUpSpeed, 10.0);
    });

    test('Ratio helper works correctly', () {
      final bar = ProgressBar.create(currentValue: 50.0, maxValue: 100.0);
      expect(bar.ratio, 0.5);

      bar.currentValue = 150.0;
      expect(bar.ratio, 1.0); // clamped

      bar.currentValue = -50.0;
      expect(bar.ratio, 0.0); // clamped

      bar.maxValue = 0.0;
      bar.currentValue = 10.0;
      expect(bar.ratio, 1.0); // division by zero handled safely
    });

    test('Data is correctly backed by Float32List', () {
      final list = Float32List(16);
      list[0] = 77.0; // currentValue
      list[1] = 100.0; // maxValue

      final bar = ProgressBar(list);
      expect(bar.currentValue, 77.0);
      expect(bar.maxValue, 100.0);
    });
  });
}
