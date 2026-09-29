import 'dart:typed_data';

extension type Rotation(Float32List data) {
  Rotation.create(double radians)
      : this(Float32List(1)
          ..[0] = radians);

  double get radians => data[0];
  set radians(double value) => data[0] = value;
}
