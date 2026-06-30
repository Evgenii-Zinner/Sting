import 'dart:ui';

import 'dart:math' as math;

class Renderer {
  final Color clearColor;
  final double? virtualWidth;
  final double? virtualHeight;

  Renderer({
    this.clearColor = const Color(0xFF000000),
    this.virtualWidth,
    this.virtualHeight,
  });

  /// Calculates the destination Rect in physical space where the virtual screen will be drawn.
  /// If virtual width/height are not set, it returns the physical size rect.
  Rect calculateVirtualRect(Size physicalSize) {
    if (virtualWidth == null || virtualHeight == null) {
      return Offset.zero & physicalSize;
    }

    final scaleX = physicalSize.width / virtualWidth!;
    final scaleY = physicalSize.height / virtualHeight!;
    final scale = math.min(scaleX, scaleY);

    final scaledWidth = virtualWidth! * scale;
    final scaledHeight = virtualHeight! * scale;

    final offsetX = (physicalSize.width - scaledWidth) / 2.0;
    final offsetY = (physicalSize.height - scaledHeight) / 2.0;

    return Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight);
  }

  /// Maps a physical X coordinate from pointer events back into the virtual coordinate space.
  double mapPointerX(double physicalX, Size physicalSize) {
    if (virtualWidth == null || virtualHeight == null) return physicalX;
    final rect = calculateVirtualRect(physicalSize);
    final scale = rect.width / virtualWidth!;
    return (physicalX - rect.left) / scale;
  }

  /// Maps a physical Y coordinate from pointer events back into the virtual coordinate space.
  double mapPointerY(double physicalY, Size physicalSize) {
    if (virtualWidth == null || virtualHeight == null) return physicalY;
    final rect = calculateVirtualRect(physicalSize);
    final scale = rect.height / virtualHeight!;
    return (physicalY - rect.top) / scale;
  }

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
      if (virtualWidth != null && virtualHeight != null) {
        final rect = calculateVirtualRect(physicalSize);
        final scale = rect.width / virtualWidth!;

        canvas.save();
        canvas.translate(rect.left, rect.top);
        canvas.scale(scale, scale);
        canvas.clipRect(Offset.zero & Size(virtualWidth!, virtualHeight!));

        onRender(canvas, Size(virtualWidth!, virtualHeight!));

        canvas.restore();
      } else {
        onRender(canvas, physicalSize);
      }
    }

    final picture = recorder.endRecording();

    final sceneBuilder = SceneBuilder();
    sceneBuilder.addPicture(Offset.zero, picture);

    final scene = sceneBuilder.build();

    // Render the scene to the view
    view.render(scene);
  }
}
