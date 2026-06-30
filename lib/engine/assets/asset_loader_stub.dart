import 'dart:ui';

class AssetLoader {
  static Future<Image> loadImage(String filePath) {
    throw UnsupportedError('loadImage is not supported on this platform');
  }

  static Future<Image> streamRawImage(
    String filePath,
    int width,
    int height, {
    PixelFormat format = PixelFormat.rgba8888,
  }) {
    throw UnsupportedError('streamRawImage is not supported on this platform');
  }

  static Future<Image> loadEmbeddedImage(String base64String) {
    throw UnsupportedError('loadEmbeddedImage is not supported on this platform');
  }
}
