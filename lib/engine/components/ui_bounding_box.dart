import 'dart:typed_data';

/// Represents a screen-space AABB bounding box for UI elements.
/// Uses a flat `Float32List` of length 5 to avoid allocations per frame.
/// Index 0: x coordinate (screen-space)
/// Index 1: y coordinate (screen-space)
/// Index 2: width
/// Index 3: height
/// Index 4: pointerId (defaults to -1.0, meaning no pointer is interacting)
extension type UIBoundingBox(Float32List _data) {
  /// Creates a new UIBoundingBox component.
  factory UIBoundingBox.fromBounds({
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    final data = Float32List(5);
    data[0] = x;
    data[1] = y;
    data[2] = width;
    data[3] = height;
    data[4] = -1.0;
    return UIBoundingBox(data);
  }

  double get x => _data[0];
  set x(double value) => _data[0] = value;

  double get y => _data[1];
  set y(double value) => _data[1] = value;

  double get width => _data[2];
  set width(double value) => _data[2] = value;

  double get height => _data[3];
  set height(double value) => _data[3] = value;

  double get pointerId => _data[4];
  set pointerId(double value) => _data[4] = value;
}
