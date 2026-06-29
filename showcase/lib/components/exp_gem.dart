import 'dart:typed_data';

/// Component representing an experience gem.
extension type ExpGem(Int32List _data) {
  /// Creates a new ExpGem component.
  factory ExpGem.create(int xpValue) {
    final data = Int32List(1);
    data[0] = xpValue;
    return ExpGem(data);
  }

  int get xpValue => _data[0];
  set xpValue(int value) => _data[0] = value;
}
