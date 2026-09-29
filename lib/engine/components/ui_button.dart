import 'dart:typed_data';

/// Zero-allocation UI Button component.
extension type UIButton(Float32List data) {
  UIButton.create({
    required double relativeX,
    required double relativeY,
    required double width,
    required double height,
    double state = 0.0,
    double normalColorHex = 0xFF3A4768,
    double hoverColorHex = 0xFF4A5778,
    double pressedColorHex = 0xFF2A3758,
    double borderColorHex = 0xFF00E5FF,
    double borderWidth = 1.0,
    double borderRadius = 2.0,
    double wasClicked = 0.0,
  }) : this(Float32List(12)
          ..[0] = relativeX
          ..[1] = relativeY
          ..[2] = width
          ..[3] = height
          ..[4] = state
          ..[5] = normalColorHex
          ..[6] = hoverColorHex
          ..[7] = pressedColorHex
          ..[8] = borderColorHex
          ..[9] = borderWidth
          ..[10] = borderRadius
          ..[11] = wasClicked);

  double get relativeX => data[0];
  set relativeX(double value) => data[0] = value;

  double get relativeY => data[1];
  set relativeY(double value) => data[1] = value;

  double get width => data[2];
  set width(double value) => data[2] = value;

  double get height => data[3];
  set height(double value) => data[3] = value;

  double get state => data[4];
  set state(double value) => data[4] = value;

  double get normalColorHex => data[5];
  set normalColorHex(double value) => data[5] = value;

  double get hoverColorHex => data[6];
  set hoverColorHex(double value) => data[6] = value;

  double get pressedColorHex => data[7];
  set pressedColorHex(double value) => data[7] = value;

  double get borderColorHex => data[8];
  set borderColorHex(double value) => data[8] = value;

  double get borderWidth => data[9];
  set borderWidth(double value) => data[9] = value;

  double get borderRadius => data[10];
  set borderRadius(double value) => data[10] = value;

  double get wasClicked => data[11];
  set wasClicked(double value) => data[11] = value;
}
