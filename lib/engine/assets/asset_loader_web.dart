import 'dart:async';
import 'dart:convert';
import 'dart:ui';

class AssetLoader {
  static Future<Image> loadImage(String filePath) {
    throw UnsupportedError(
        'loadImage is not supported on Web. Use loadEmbeddedImage instead.');
  }

  static Future<Image> streamRawImage(
    String filePath,
    int width,
    int height, {
    PixelFormat format = PixelFormat.rgba8888,
  }) {
    throw UnsupportedError(
        'streamRawImage is not supported on Web. Use loadEmbeddedImage instead.');
  }

  static Future<Image> loadEmbeddedImage(String base64String) async {
    final bytes = base64Decode(base64String);
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}
