import 'dart:typed_data';

/// A flat AudioEmitter component using a Dart extension type over a ByteData.
/// Byte Offsets:
/// 0: soundId (Int32)
/// 4: maxDistance (Float32)
/// 8: referenceDistance (Float32)
/// 12: volume (Float32)
/// 16: rolloffFactor (Float32)
/// 20: isLooping (Int32)
/// 24: isPlaying (Int32)
extension type AudioEmitter(ByteData data) {
  static const int sizeInBytes = 28;

  /// Creates a new AudioEmitter component.
  AudioEmitter.create({
    required int soundId,
    double maxDistance = 1000.0,
    double referenceDistance = 100.0,
    double volume = 1.0,
    double rolloffFactor = 1.0,
    bool isLooping = false,
    bool isPlaying = true,
  }) : this(ByteData(sizeInBytes)
          ..setInt32(0, soundId, Endian.host)
          ..setFloat32(4, maxDistance, Endian.host)
          ..setFloat32(8, referenceDistance, Endian.host)
          ..setFloat32(12, volume, Endian.host)
          ..setFloat32(16, rolloffFactor, Endian.host)
          ..setInt32(20, isLooping ? 1 : 0, Endian.host)
          ..setInt32(24, isPlaying ? 1 : 0, Endian.host));

  int get soundId => data.getInt32(0, Endian.host);
  set soundId(int value) => data.setInt32(0, value, Endian.host);

  double get maxDistance => data.getFloat32(4, Endian.host);
  set maxDistance(double value) => data.setFloat32(4, value, Endian.host);

  double get referenceDistance => data.getFloat32(8, Endian.host);
  set referenceDistance(double value) => data.setFloat32(8, value, Endian.host);

  double get volume => data.getFloat32(12, Endian.host);
  set volume(double value) => data.setFloat32(12, value, Endian.host);

  double get rolloffFactor => data.getFloat32(16, Endian.host);
  set rolloffFactor(double value) => data.setFloat32(16, value, Endian.host);

  bool get isLooping => data.getInt32(20, Endian.host) != 0;
  set isLooping(bool value) => data.setInt32(20, value ? 1 : 0, Endian.host);

  bool get isPlaying => data.getInt32(24, Endian.host) != 0;
  set isPlaying(bool value) => data.setInt32(24, value ? 1 : 0, Endian.host);
}
