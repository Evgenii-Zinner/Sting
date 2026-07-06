import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/text_render.dart';

void main() {
  group('TextRender Component', () {
    test('initializes with default values', () {
      final textRender = TextRender();
      expect(textRender.text, '');
      expect(textRender.x, 0.0);
      expect(textRender.y, 0.0);
      expect(textRender.color, 0xFFFFFFFF);
      expect(textRender.fontSize, 14.0);
      expect(textRender.isDirty, isTrue);
      expect(textRender.cachedOffset, const Offset(0.0, 0.0));
      expect(textRender.cachedParagraph, isNull);
    });

    test('initializes with custom values', () {
      final textRender = TextRender(
        text: 'Score: 100',
        x: 10.0,
        y: 20.0,
        color: 0xFFFF0000,
        fontSize: 24.0,
      );
      expect(textRender.text, 'Score: 100');
      expect(textRender.x, 10.0);
      expect(textRender.y, 20.0);
      expect(textRender.color, 0xFFFF0000);
      expect(textRender.fontSize, 24.0);
      expect(textRender.isDirty, isTrue);
      expect(textRender.cachedOffset, const Offset(10.0, 20.0));
    });

    test('changing text sets isDirty to true', () {
      final textRender = TextRender(text: 'Score: 0');
      textRender.clearDirty();
      expect(textRender.isDirty, isFalse);

      textRender.text = 'Score: 10';
      expect(textRender.isDirty, isTrue);
      expect(textRender.text, 'Score: 10');
    });

    test('changing text to same value does not set isDirty to true', () {
      final textRender = TextRender(text: 'Score: 0');
      textRender.clearDirty();
      expect(textRender.isDirty, isFalse);

      textRender.text = 'Score: 0';
      expect(textRender.isDirty, isFalse);
    });

    test('changing coordinates updates cached offset but does not set isDirty',
        () {
      final textRender = TextRender(x: 10.0, y: 10.0);
      textRender.clearDirty();

      textRender.x = 20.0;
      expect(textRender.isDirty,
          isFalse); // Position change shouldn't require paragraph rebuild
      expect(textRender.cachedOffset, const Offset(20.0, 10.0));

      textRender.y = 30.0;
      expect(textRender.isDirty, isFalse);
      expect(textRender.cachedOffset, const Offset(20.0, 30.0));
    });

    test('changing color sets isDirty to true', () {
      final textRender = TextRender(color: 0xFF000000);
      textRender.clearDirty();

      textRender.color = 0xFFFFFFFF;
      expect(textRender.isDirty, isTrue);
      expect(textRender.color, 0xFFFFFFFF);
    });

    test('changing font size sets isDirty to true', () {
      final textRender = TextRender(fontSize: 12.0);
      textRender.clearDirty();

      textRender.fontSize = 16.0;
      expect(textRender.isDirty, isTrue);
      expect(textRender.fontSize, 16.0);
    });
  });
}
