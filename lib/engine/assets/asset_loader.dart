import 'dart:io';
import 'dart:ui';

class AssetLoader {
  static Future<Image> loadImage(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}
