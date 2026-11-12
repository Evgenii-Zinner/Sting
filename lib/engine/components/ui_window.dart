import 'dart:typed_data';

/// Zero-allocation UI Window component.
extension type UIWindow(Float32List data) {
  /// Creates a new [UIWindow] component with the given layout and style.
  UIWindow.create({
    required double x,
    required double y,
    required double width,
    required double height,
    double titleBarHeight = 26.0,
    double backgroundColorHex = 0xEE101424,
    double titleBarColorHex = 0xFF1E2846,
    double borderColorHex = 0xFF00E5FF,
    double borderWidth = 1.5,
    double borderRadius = 4.0,
    double isDragging = 0.0,
    double dragOffsetX = 0.0,
    double dragOffsetY = 0.0,
    double isVisible = 1.0,
  }) : this(Float32List(14)
          ..[0] = x
          ..[1] = y
          ..[2] = width
          ..[3] = height
          ..[4] = titleBarHeight
          ..[5] = backgroundColorHex
          ..[6] = titleBarColorHex
          ..[7] = borderColorHex
          ..[8] = borderWidth
          ..[9] = borderRadius
          ..[10] = isDragging
          ..[11] = dragOffsetX
          ..[12] = dragOffsetY
          ..[13] = isVisible);

  /// Horizontal position of the window top-left corner.
  double get x => data[0];
  set x(double value) => data[0] = value;

  /// Vertical position of the window top-left corner.
  double get y => data[1];
  set y(double value) => data[1] = value;

  /// Width of the window.
  double get width => data[2];
  set width(double value) => data[2] = value;

  /// Height of the window.
  double get height => data[3];
  set height(double value) => data[3] = value;

  /// Height of the draggable title bar header.
  double get titleBarHeight => data[4];
  set titleBarHeight(double value) => data[4] = value;

  /// Background color hex.
  double get backgroundColorHex => data[5];
  set backgroundColorHex(double value) => data[5] = value;

  /// Title bar color hex.
  double get titleBarColorHex => data[6];
  set titleBarColorHex(double value) => data[6] = value;

  /// Border outline color hex.
  double get borderColorHex => data[7];
  set borderColorHex(double value) => data[7] = value;

  /// Border outline stroke width.
  double get borderWidth => data[8];
  set borderWidth(double value) => data[8] = value;

  /// Corner radius for rounded corners.
  double get borderRadius => data[9];
  set borderRadius(double value) => data[9] = value;

  /// Whether the window is currently being dragged (1.0 = true, 0.0 = false).
  double get isDragging => data[10];
  set isDragging(double value) => data[10] = value;

  /// Pointer X offset from window origin when drag started.
  double get dragOffsetX => data[11];
  set dragOffsetX(double value) => data[11] = value;

  /// Pointer Y offset from window origin when drag started.
  double get dragOffsetY => data[12];
  set dragOffsetY(double value) => data[12] = value;

  /// Whether the window is visible (1.0 = visible, 0.0 = hidden).
  double get isVisible => data[13];
  set isVisible(double value) => data[13] = value;
}
