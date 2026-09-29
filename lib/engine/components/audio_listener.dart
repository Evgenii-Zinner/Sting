import 'dart:typed_data';

/// A flat AudioListener component using a Dart extension type over a Float32List.
/// Index 0: hearingRange
/// Index 1: masterVolume
extension type AudioListener(Float32List data) {
  /// Creates a new AudioListener component.
  AudioListener.create({
    double hearingRange = 1000.0,
    double masterVolume = 1.0,
  }) : this(Float32List(2)
          ..[0] = hearingRange
          ..[1] = masterVolume);

  double get hearingRange => data[0];
  set hearingRange(double value) => data[0] = value;

  double get masterVolume => data[1];
  set masterVolume(double value) => data[1] = value;
}
