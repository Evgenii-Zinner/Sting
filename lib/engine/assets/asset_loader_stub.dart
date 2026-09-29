import 'dart:typed_data';
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
    throw UnsupportedError(
        'loadEmbeddedImage is not supported on this platform');
  }

  static Future<FragmentProgram> loadShader(String assetKey) {
    throw UnsupportedError('loadShader is not supported on this platform');
  }

  static Future<Uint8List> loadBytes(String filePath) {
    throw UnsupportedError('loadBytes is not supported on this platform');
  }

  static Future<String> loadText(String filePath) {
    throw UnsupportedError('loadText is not supported on this platform');
  }
}
