import 'dart:typed_data';

/// Component representing an entity's health.
extension type Health(Int32List _data) {
  /// Creates a new Health component.
  factory Health.create(int maxHealth) {
    final data = Int32List(2);
    data[0] = maxHealth;
    data[1] = maxHealth;
    return Health(data);
  }

  int get current => _data[0];
  set current(int value) => _data[0] = value;

  int get max => _data[1];
  set max(int value) => _data[1] = value;
}
