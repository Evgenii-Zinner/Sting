import 'dart:typed_data';

extension type LocalTransform(Float32List data) {
  LocalTransform.create(double lx, double ly, double localRotation, double localScaleX, double localScaleY)
      : this(Float32List(5)
          ..[0] = lx
          ..[1] = ly
          ..[2] = localRotation
          ..[3] = localScaleX
          ..[4] = localScaleY);

  double get lx => data[0];
  set lx(double value) => data[0] = value;

  double get ly => data[1];
  set ly(double value) => data[1] = value;

  double get localRotation => data[2];
  set localRotation(double value) => data[2] = value;

  double get localScaleX => data[3];
  set localScaleX(double value) => data[3] = value;

  double get localScaleY => data[4];
  set localScaleY(double value) => data[4] = value;
}
