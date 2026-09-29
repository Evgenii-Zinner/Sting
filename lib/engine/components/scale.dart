import 'dart:typed_data';

extension type Scale(Float32List data) {
  Scale.create(double x, double y)
      : this(Float32List(2)
          ..[0] = x
          ..[1] = y);

  double get x => data[0];
  set x(double value) => data[0] = value;

  double get y => data[1];
  set y(double value) => data[1] = value;
}
