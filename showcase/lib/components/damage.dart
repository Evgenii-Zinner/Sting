import 'dart:typed_data';

/// Component representing damage dealt by an entity on collision.
extension type Damage(Int32List _data) {
  /// Creates a new Damage component.
  factory Damage.create(int amount) {
    final data = Int32List(1);
    data[0] = amount;
    return Damage(data);
  }

  int get amount => _data[0];
  set amount(int value) => _data[0] = value;
}
