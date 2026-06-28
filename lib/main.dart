import 'dart:ui';
import 'engine/renderer.dart';

int frameCount = 0;
final renderer = Renderer();

void initEngine() {
  final dispatcher = PlatformDispatcher.instance;

  dispatcher.onBeginFrame = (Duration timeStamp) {
    frameCount++;
    print('Engine ticking... Frame: $frameCount, Timestamp: $timeStamp');
    // Request next frame to keep loop going
    dispatcher.scheduleFrame();
  };

  dispatcher.onDrawFrame = () {
    renderer.renderFrame();
    // In later steps, this is where Canvas.drawAtlas and SceneBuilder will be used.
  };

  // Kick off the first frame
  dispatcher.scheduleFrame();
}

void main() {
  initEngine();
}
