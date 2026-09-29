import 'dart:typed_data';

extension type FloatingText(Float32List data) {
  FloatingText.create(
      double worldX,
      double worldY,
      double velocityX,
      double velocityY,
      double lifetime,
      double maxLifetime,
      double alpha,
      double scale,
      double numberValue)
      : this(Float32List(9)
          ..[0] = worldX
          ..[1] = worldY
          ..[2] = velocityX
          ..[3] = velocityY
          ..[4] = lifetime
          ..[5] = maxLifetime
          ..[6] = alpha
          ..[7] = scale
          ..[8] = numberValue);

  double get worldX => data[0];
  set worldX(double value) => data[0] = value;

  double get worldY => data[1];
  set worldY(double value) => data[1] = value;

  double get velocityX => data[2];
  set velocityX(double value) => data[2] = value;

  double get velocityY => data[3];
  set velocityY(double value) => data[3] = value;

  double get lifetime => data[4];
  set lifetime(double value) => data[4] = value;

  double get maxLifetime => data[5];
  set maxLifetime(double value) => data[5] = value;

  double get alpha => data[6];
  set alpha(double value) => data[6] = value;

  double get scale => data[7];
  set scale(double value) => data[7] = value;

  double get numberValue => data[8];
  set numberValue(double value) => data[8] = value;
}
