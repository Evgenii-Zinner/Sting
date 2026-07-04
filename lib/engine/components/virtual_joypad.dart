import 'dart:typed_data';

/// A virtual joypad component for on-screen touch controls.
/// Implemented as a Dart 3 extension type over a `Float32List` to ensure
/// zero per-frame memory allocations.
///
/// Indices mapping:
/// 0: vectorX (-1.0 to 1.0)
/// 1: vectorY (-1.0 to 1.0)
/// 2: maxRadius (maximum pixel radius the knob can travel from center)
/// 3: centerX (the base X coordinate of the joypad center)
/// 4: centerY (the base Y coordinate of the joypad center)
/// 5: knobEntityId (the entity ID of the visual knob component, stored as float)
/// 6: activePointerId (the current active pointer ID manipulating the pad, -1.0 if none)
extension type VirtualJoypad(Float32List _data) {
  /// Creates a new VirtualJoypad with the given [maxRadius], [centerX], and [centerY].
  factory VirtualJoypad.create({
    required double maxRadius,
    required double centerX,
    required double centerY,
    double knobEntityId = -1.0,
  }) {
    final data = Float32List(7);
    data[0] = 0.0;
    data[1] = 0.0;
    data[2] = maxRadius;
    data[3] = centerX;
    data[4] = centerY;
    data[5] = knobEntityId;
    data[6] = -1.0;
    return VirtualJoypad(data);
  }

  double get vectorX => _data[0];
  set vectorX(double value) => _data[0] = value;

  double get vectorY => _data[1];
  set vectorY(double value) => _data[1] = value;

  double get maxRadius => _data[2];
  set maxRadius(double value) => _data[2] = value;

  double get centerX => _data[3];
  set centerX(double value) => _data[3] = value;

  double get centerY => _data[4];
  set centerY(double value) => _data[4] = value;

  double get knobEntityId => _data[5];
  set knobEntityId(double value) => _data[5] = value;

  double get activePointerId => _data[6];
  set activePointerId(double value) => _data[6] = value;
}
