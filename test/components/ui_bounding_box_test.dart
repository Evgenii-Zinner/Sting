import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/ui_bounding_box.dart';

void main() {
  group('UIBoundingBox', () {
    test('initializes correctly', () {
      final box = UIBoundingBox.fromBounds(x: 10, y: 20, width: 100, height: 50);

      expect(box.x, 10);
      expect(box.y, 20);
      expect(box.width, 100);
      expect(box.height, 50);
      expect(box.pointerId, -1.0);
    });

    test('updates values correctly', () {
      final box = UIBoundingBox.fromBounds(x: 0, y: 0, width: 0, height: 0);

      box.x = 5.0;
      box.y = 15.0;
      box.width = 50.0;
      box.height = 25.0;
      box.pointerId = 2.0;

      expect(box.x, 5.0);
      expect(box.y, 15.0);
      expect(box.width, 50.0);
      expect(box.height, 25.0);
      expect(box.pointerId, 2.0);
    });
  });
}
