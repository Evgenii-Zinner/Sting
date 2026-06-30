import 'dart:ui';

class Renderer {
  final Color clearColor;

  Renderer({this.clearColor = const Color(0xFF000000)});

  void renderFrame({void Function(Canvas canvas, Size size)? onRender}) {
    final dispatcher = PlatformDispatcher.instance;
    if (dispatcher.views.isEmpty) return;

    final view = dispatcher.views.first;
    final physicalSize = view.physicalSize;

    // In test environments, physicalSize might be empty.
    if (physicalSize.isEmpty) return;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & physicalSize);

    // Clear the screen
    canvas.drawColor(clearColor, BlendMode.src);

    if (onRender != null) {
      onRender(canvas, physicalSize);
    }

    final picture = recorder.endRecording();

    final sceneBuilder = SceneBuilder();
    sceneBuilder.addPicture(Offset.zero, picture);

    final scene = sceneBuilder.build();

    // Render the scene to the view
    view.render(scene);
  }
}
