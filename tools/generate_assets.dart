import 'dart:io';
import 'package:image/image.dart';

void main() async {
  final outDir = Directory('showcase/assets');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  // 1. Generate Player Sprite Sheet (128x32, 4 frames of 32x32)
  final playerImg = Image(width: 128, height: 32);
  for (int i = 0; i < 4; i++) {
    // Fill each frame with slightly different blue
    int blue = 200 + (i * 15);
    fillRect(playerImg,
        x1: i * 32,
        y1: 0,
        x2: i * 32 + 31,
        y2: 31,
        color: ColorRgb8(0, 0, blue));
    // Draw a small lighter square in the middle to show direction/animation
    fillRect(playerImg,
        x1: i * 32 + 8 + i,
        y1: 8 + i,
        x2: i * 32 + 23 - i,
        y2: 23 - i,
        color: ColorRgb8(100, 100, 255));
  }
  File('${outDir.path}/player.png').writeAsBytesSync(encodePng(playerImg));
  print('Generated player.png');

  // 2. Generate Enemy Sprite Sheet (128x32, 4 frames of 32x32)
  final enemyImg = Image(width: 128, height: 32);
  for (int i = 0; i < 4; i++) {
    // Fill each frame with slightly different red
    int red = 200 + (i * 15);
    fillRect(enemyImg,
        x1: i * 32,
        y1: 0,
        x2: i * 32 + 31,
        y2: 31,
        color: ColorRgb8(red, 0, 0));
    // Draw eyes or pattern
    fillRect(enemyImg,
        x1: i * 32 + 8,
        y1: 8,
        x2: i * 32 + 12,
        y2: 12,
        color: ColorRgb8(255, 255, 0));
    fillRect(enemyImg,
        x1: i * 32 + 20,
        y1: 8,
        x2: i * 32 + 24,
        y2: 12,
        color: ColorRgb8(255, 255, 0));
  }
  File('${outDir.path}/enemy.png').writeAsBytesSync(encodePng(enemyImg));
  print('Generated enemy.png');

  // 3. Generate Projectile (16x16)
  final projectileImg = Image(width: 16, height: 16);
  fillCircle(projectileImg,
      x: 8, y: 8, radius: 8, color: ColorRgb8(255, 255, 0));
  fillCircle(projectileImg,
      x: 8, y: 8, radius: 4, color: ColorRgb8(255, 128, 0));
  File('${outDir.path}/projectile.png')
      .writeAsBytesSync(encodePng(projectileImg));
  print('Generated projectile.png');

  // 4. Generate Tilemap Sprite Sheet (128x128, 4x4 tiles of 32x32)
  final tilemapImg = Image(width: 128, height: 128);
  for (int y = 0; y < 4; y++) {
    for (int x = 0; x < 4; x++) {
      Color c;
      if (y == 0) {
        // grass/floor variations
        c = ColorRgb8(0, 100 + (x * 30), 0);
      } else if (y == 1) {
        // wall variations
        c = ColorRgb8(100 + (x * 20), 100 + (x * 20), 100 + (x * 20));
      } else if (y == 2) {
        // obstacles/rocks
        c = ColorRgb8(150 + (x * 10), 100 + (x * 10), 50 + (x * 10));
      } else {
        // water/void
        c = ColorRgb8(0, 0, 150 + (x * 20));
      }

      fillRect(tilemapImg,
          x1: x * 32, y1: y * 32, x2: x * 32 + 31, y2: y * 32 + 31, color: c);
      // Draw grid outline for tile separation visually
      drawLine(tilemapImg,
          x1: x * 32,
          y1: y * 32,
          x2: x * 32 + 31,
          y2: y * 32,
          color: ColorRgb8(0, 0, 0));
      drawLine(tilemapImg,
          x1: x * 32,
          y1: y * 32,
          x2: x * 32,
          y2: y * 32 + 31,
          color: ColorRgb8(0, 0, 0));
    }
  }
  File('${outDir.path}/tilemap.png').writeAsBytesSync(encodePng(tilemapImg));
  print('Generated tilemap.png');
}
