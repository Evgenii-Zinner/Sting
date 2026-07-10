import 'dart:typed_data';

/// Component for Utility AI storing task ID, target entity, parameter coordinates,
/// and parallel Float32List slices for tension and damping.
extension type UtilityAI(ByteData data) {
  /// The size of the header in bytes.
  static const int _headerSize = 16;

  /// The size of a float32 in bytes.
  static const int _floatSize = 4;

  /// Creates a UtilityAI component with space for [numConsiderations] considerations.
  UtilityAI.create(int activeTaskId, int targetEntityId, double targetX, double targetY, int numConsiderations)
      : this(ByteData(_headerSize + numConsiderations * _floatSize * 2)
          ..setInt32(0, activeTaskId, Endian.host)
          ..setInt32(4, targetEntityId, Endian.host)
          ..setFloat32(8, targetX, Endian.host)
          ..setFloat32(12, targetY, Endian.host));

  int get activeTaskId => data.getInt32(0, Endian.host);
  set activeTaskId(int value) => data.setInt32(0, value, Endian.host);

  int get targetEntityId => data.getInt32(4, Endian.host);
  set targetEntityId(int value) => data.setInt32(4, value, Endian.host);

  double get targetX => data.getFloat32(8, Endian.host);
  set targetX(double value) => data.setFloat32(8, value, Endian.host);

  double get targetY => data.getFloat32(12, Endian.host);
  set targetY(double value) => data.setFloat32(12, value, Endian.host);

  /// Gets the number of considerations (derived from buffer length).
  int get numConsiderations => (data.lengthInBytes - _headerSize) ~/ (_floatSize * 2);

  /// Returns a Float32List view over the tension considerations.
  Float32List get tension {
    final numCons = numConsiderations;
    return Float32List.sublistView(data, _headerSize, _headerSize + numCons * _floatSize);
  }

  /// Returns a Float32List view over the damping considerations.
  Float32List get damping {
    final numCons = numConsiderations;
    final offset = _headerSize + numCons * _floatSize;
    return Float32List.sublistView(data, offset, offset + numCons * _floatSize);
  }
}
