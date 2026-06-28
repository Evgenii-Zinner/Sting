import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

class _DecodeRequest {
  final String filePath;
  final SendPort sendPort;
  _DecodeRequest(this.filePath, this.sendPort);
}

void _readPixelsIsolate(_DecodeRequest request) {
  try {
    final file = File(request.filePath);
    final bytes = file.readAsBytesSync();
    final transferable = TransferableTypedData.fromList([bytes]);
    request.sendPort.send(transferable);
  } catch (e) {
    request.sendPort.send(Exception(e.toString()));
  }
}

class AssetLoader {
  static Future<Image> loadImage(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  /// Streams raw pixel data using a background isolate, avoiding main thread blockage.
  static Future<Image> streamRawImage(
    String filePath,
    int width,
    int height, {
    PixelFormat format = PixelFormat.rgba8888,
  }) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _readPixelsIsolate,
      _DecodeRequest(filePath, receivePort.sendPort),
    );

    final completer = Completer<Image>();
    receivePort.listen((message) {
      if (message is TransferableTypedData) {
        try {
          final pixels = message.materialize().asUint8List();
          decodeImageFromPixels(
            pixels,
            width,
            height,
            format,
            (image) {
              completer.complete(image);
              receivePort.close();
            },
          );
        } catch (e) {
          completer.completeError(Exception(e.toString()));
          receivePort.close();
        }
      } else if (message is Exception) {
        completer.completeError(message);
        receivePort.close();
      }
    });

    return completer.future;
  }
}
