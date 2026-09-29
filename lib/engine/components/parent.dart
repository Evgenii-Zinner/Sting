import 'dart:typed_data';

extension type Parent(Int32List data) {
  Parent.create(int entityId) : this(Int32List(1)..[0] = entityId);

  int get entityId => data[0];
  set entityId(int value) => data[0] = value;
}
