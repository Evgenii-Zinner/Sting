import 'dart:typed_data';

/// A Data-Oriented tag component that marks an entity as a shadow caster.
/// It uses a Float32List with length 1 to just hold a single "active" flag,
/// allowing it to conform to our extension type component pattern.
extension type ShadowCaster(Float32List _data) implements Float32List {
  static const int componentSize = 1;

  ShadowCaster.create({bool active = true}) : _data = Float32List(componentSize) {
    this.active = active;
  }

  bool get active => _data[0] > 0.0;
  set active(bool value) => _data[0] = value ? 1.0 : 0.0;
}
