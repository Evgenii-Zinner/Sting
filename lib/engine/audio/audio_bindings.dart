import 'dart:async';

/// Low-level audio binding interface.
/// Pure Dart stubbed/pluggable implementation decoupled from native plugins.
class AudioBindings {
  static int _nextHandle = 1;

  static Future<void> init() async {}

  static Future<void> loadSound(int soundId, String path) async {}

  static void unloadSound(int soundId) {}

  static int play(
    int soundId, {
    double volume = 1.0,
    double pitch = 1.0,
    bool loop = false,
  }) {
    return _nextHandle++;
  }

  static void stop(int handle) {}
}
