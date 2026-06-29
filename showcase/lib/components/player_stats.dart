import 'dart:typed_data';

/// Component representing player statistics like score and experience.
extension type PlayerStats(Int32List _data) {
  /// Creates a new PlayerStats component.
  factory PlayerStats.create() {
    final data = Int32List(3);
    data[0] = 0; // score
    data[1] = 0; // xp
    data[2] = 1; // level
    return PlayerStats(data);
  }

  int get score => _data[0];
  set score(int value) => _data[0] = value;

  int get xp => _data[1];
  set xp(int value) => _data[1] = value;

  int get level => _data[2];
  set level(int value) => _data[2] = value;
}
