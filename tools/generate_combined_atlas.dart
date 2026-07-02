import 'dart:io';
import 'package:image/image.dart';

void main() async {
  final outDir = Directory('showcase/assets');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  // Final atlas size
  final atlas = Image(width: 512, height: 512);

  // 1. Generate Tilemap Sprite Sheet (128x128, 4x4 tiles of 32x32) at top-left
  for (int y = 0; y < 4; y++) {
    for (int x = 0; x < 4; x++) {
      Color c;
      if (y == 0) {
        c = ColorRgb8(0, 100 + (x * 30), 0); // grass
      } else if (y == 1) {
        c = ColorRgb8(100 + (x * 20), 100 + (x * 20), 100 + (x * 20)); // wall
      } else if (y == 2) {
        c = ColorRgb8(150 + (x * 10), 100 + (x * 10), 50 + (x * 10)); // rocks
      } else {
        c = ColorRgb8(0, 0, 150 + (x * 20)); // water
      }

      fillRect(atlas, x1: x * 32, y1: y * 32, x2: x * 32 + 31, y2: y * 32 + 31, color: c);
      drawLine(atlas, x1: x * 32, y1: y * 32, x2: x * 32 + 31, y2: y * 32, color: ColorRgb8(0, 0, 0));
      drawLine(atlas, x1: x * 32, y1: y * 32, x2: x * 32, y2: y * 32 + 31, color: ColorRgb8(0, 0, 0));
    }
  }

  // 2. Generate Player Sprite Sheet (128x32, 4 frames of 32x32) at y = 128
  for (int i = 0; i < 4; i++) {
    int blue = 200 + (i * 15);
    fillRect(atlas, x1: i * 32, y1: 128, x2: i * 32 + 31, y2: 128 + 31, color: ColorRgb8(0, 0, blue));
    fillRect(atlas, x1: i * 32 + 8 + i, y1: 128 + 8 + i, x2: i * 32 + 23 - i, y2: 128 + 23 - i, color: ColorRgb8(100, 100, 255));
  }

  // 3. Generate Enemy Sprite Sheet (128x32, 4 frames of 32x32) at y = 160
  for (int i = 0; i < 4; i++) {
    int red = 200 + (i * 15);
    fillRect(atlas, x1: i * 32, y1: 160, x2: i * 32 + 31, y2: 160 + 31, color: ColorRgb8(red, 0, 0));
    fillRect(atlas, x1: i * 32 + 8, y1: 160 + 8, x2: i * 32 + 12, y2: 160 + 12, color: ColorRgb8(255, 255, 0));
    fillRect(atlas, x1: i * 32 + 20, y1: 160 + 8, x2: i * 32 + 24, y2: 160 + 12, color: ColorRgb8(255, 255, 0));
  }

  // 4. Generate Projectile (16x16) at x = 0, y = 192
  fillCircle(atlas, x: 8, y: 192 + 8, radius: 8, color: ColorRgb8(255, 255, 0));
  fillCircle(atlas, x: 8, y: 192 + 8, radius: 4, color: ColorRgb8(255, 128, 0));

  File('${outDir.path}/atlas.png').writeAsBytesSync(encodePng(atlas));
  print('Generated atlas.png');
}
