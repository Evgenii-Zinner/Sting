import 'dart:typed_data';

/// A CompoundBoundingBox component using a Dart extension type over a Float32List.
/// Index 0: minX, Index 1: minY, Index 2: maxX, Index 3: maxY, Index 4: childCount, Index 5: isDirty.
extension type CompoundBoundingBox(Float32List data) {
  /// Creates a new CompoundBoundingBox component.
  CompoundBoundingBox.create()
      : this(Float32List(6)
          ..[0] = 0.0
          ..[1] = 0.0
          ..[2] = 0.0
          ..[3] = 0.0
          ..[4] = 0.0
          ..[5] = 0.0);

  double get minX => data[0];
  set minX(double value) => data[0] = value;

  double get minY => data[1];
  set minY(double value) => data[1] = value;

  double get maxX => data[2];
  set maxX(double value) => data[2] = value;

  double get maxY => data[3];
  set maxY(double value) => data[3] = value;

  double get childCount => data[4];
  set childCount(double value) => data[4] = value;

  double get isDirty => data[5];
  set isDirty(double value) => data[5] = value;

  void updateBounds(double minX, double minY, double maxX, double maxY) {
    if (minX < this.minX) this.minX = minX;
    if (minY < this.minY) this.minY = minY;
    if (maxX > this.maxX) this.maxX = maxX;
    if (maxY > this.maxY) this.maxY = maxY;
  }

  void reset(double centerX, double centerY) {
    minX = centerX;
    minY = centerY;
    maxX = centerX;
    maxY = centerY;
    childCount = 0.0;
  }
}
