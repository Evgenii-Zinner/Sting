import 'dart:typed_data';

/// Component representing an experience magnet attached to a player.
extension type ExpMagnet(Float32List _data) {
  /// Creates a new ExpMagnet component.
  factory ExpMagnet.create(double radius) {
    final data = Float32List(1);
    data[0] = radius;
    return ExpMagnet(data);
  }

  double get radius => _data[0];
  set radius(double value) => _data[0] = value;
}
