import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/complex_ui.dart';

void main() {
  group('ComplexUI Component', () {
    test('Initialization sets values correctly and sets dirty flag', () {
      final ui = ComplexUI(
        x: 10,
        y: 20,
        width: 100,
        height: 50,
        backgroundColor: 0xFF00FF00,
        text: 'Button',
        textColor: 0xFF0000FF,
        fontSize: 16.0,
        borderRadius: 5.0,
      );

      expect(ui.x, 10);
      expect(ui.y, 20);
      expect(ui.width, 100);
      expect(ui.height, 50);
      expect(ui.backgroundColor, 0xFF00FF00);
      expect(ui.text, 'Button');
      expect(ui.textColor, 0xFF0000FF);
      expect(ui.fontSize, 16.0);
      expect(ui.borderRadius, 5.0);
      expect(ui.isDirty, isTrue);
      expect(ui.cachedParagraph, isNull);
      expect(ui.cachedPath, isNull);
      expect(ui.cachedPaint, isNull);
    });

    test('Setters trigger dirty flag', () {
      final ui = ComplexUI();
      ui.clearDirty();
      expect(ui.isDirty, isFalse);

      ui.width = 150;
      expect(ui.isDirty, isTrue);

      ui.clearDirty();
      ui.height = 75;
      expect(ui.isDirty, isTrue);

      ui.clearDirty();
      ui.backgroundColor = 0xFF123456;
      expect(ui.isDirty, isTrue);

      ui.clearDirty();
      ui.text = 'New Text';
      expect(ui.isDirty, isTrue);

      ui.clearDirty();
      ui.textColor = 0xFF654321;
      expect(ui.isDirty, isTrue);

      ui.clearDirty();
      ui.fontSize = 20.0;
      expect(ui.isDirty, isTrue);

      ui.clearDirty();
      ui.borderRadius = 10.0;
      expect(ui.isDirty, isTrue);
    });

    test('Setters to same value do not trigger dirty flag', () {
      final ui = ComplexUI(x: 10, y: 10, width: 100);
      ui.clearDirty();

      ui.width = 100;
      expect(ui.isDirty, isFalse);
    });

    test('Caching objects works correctly', () {
      final ui = ComplexUI();

      final paragraph = ParagraphBuilder(ParagraphStyle()).build();
      final path = Path();
      final paint = Paint();

      ui.cachedParagraph = paragraph;
      ui.cachedPath = path;
      ui.cachedPaint = paint;

      expect(ui.cachedParagraph, paragraph);
      expect(ui.cachedPath, path);
      expect(ui.cachedPaint, paint);
    });
  });
}
