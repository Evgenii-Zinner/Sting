import 'dart:io';
import 'package:image/image.dart';

void main() async {
  final outDir = Directory('showcase_starsystem/assets');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  // Final atlas size
  final atlas = Image(width: 512, height: 512);

  // Star (64x64) at 0,0
  fillCircle(atlas, x: 32, y: 32, radius: 32, color: ColorRgb8(255, 255, 0));

  // Planet 1 (32x32) at 64,0
  fillCircle(atlas, x: 64 + 16, y: 16, radius: 16, color: ColorRgb8(0, 0, 255));

  // Planet 2 (16x16) at 96,0
  fillCircle(atlas, x: 96 + 8, y: 8, radius: 8, color: ColorRgb8(255, 0, 0));

  File('${outDir.path}/atlas.png').writeAsBytesSync(encodePng(atlas));
  print('Generated atlas.png');
}
