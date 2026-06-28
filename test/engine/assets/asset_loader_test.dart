import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/assets/asset_loader.dart';

void main() {
  test('AssetLoader can load a valid image file', () async {
    // Create a temporary 1x1 PNG file
    final Uint8List transparent1x1Png = Uint8List.fromList([
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      0x00,
      0x00,
      0x00,
      0x0d,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1f,
      0x15,
      0xc4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0a,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9c,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0d,
      0x0a,
      0x2d,
      0xb4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4e,
      0x44,
      0xae,
      0x42,
      0x60,
      0x82
    ]);

    final tempFile = File('test_1x1.png');
    await tempFile.writeAsBytes(transparent1x1Png);

    try {
      final image = await AssetLoader.loadImage('test_1x1.png');
      expect(image.width, 1);
      expect(image.height, 1);
    } finally {
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    }
  });

  test('AssetLoader can stream raw image data via isolate', () async {
    final tempFile = File('test_raw_2x2.bin');
    final pixels = Uint8List(2 * 2 * 4); // 2x2 RGBA
    for (int i = 0; i < pixels.length; i++) {
      pixels[i] = 255;
    }
    await tempFile.writeAsBytes(pixels);

    try {
      final image = await AssetLoader.streamRawImage('test_raw_2x2.bin', 2, 2);
      expect(image.width, 2);
      expect(image.height, 2);
    } finally {
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    }
  });

  test('AssetLoader streamRawImage handles non-existent file gracefully',
      () async {
    expect(
      () => AssetLoader.streamRawImage('non_existent_file.bin', 2, 2),
      throwsException,
    );
  });
}
