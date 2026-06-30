import 'dart:ui';
import 'engine/renderer.dart';
import 'engine/time.dart';

int frameCount = 0;
final renderer = Renderer();
final time = Time();

void initEngine() {
  final dispatcher = PlatformDispatcher.instance;

  dispatcher.onBeginFrame = (Duration timeStamp) {
    frameCount++;
    time.update(timeStamp.inMicroseconds);

    // Fixed step loop logic processing.
    while(time.consumeFixedStep()) {
      // In later steps, ECS logic updates go here utilizing time.fixedDeltaTime.
    }

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
