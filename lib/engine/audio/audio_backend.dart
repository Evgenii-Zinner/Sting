import 'dart:async';

/// Abstract interface for low-level audio drivers.
/// Allows swapping out the underlying implementation (e.g., SoLoud, MiniAudio)
/// without changing the core engine code.
abstract class AudioBackend {
  /// Initializes the audio backend.
  Future<void> init();

  /// Loads a sound from [path] and associates it with [soundId].
  Future<void> loadSound(int soundId, String path);

  /// Unloads the sound associated with [soundId] to free memory.
  void unloadSound(int soundId);

  /// Plays the sound associated with [soundId].
  /// Returns a playback handle that can be used to stop or modify the specific playback instance.
  int play(
    int soundId, {
    double volume = 1.0,
    double pitch = 1.0,
    bool loop = false,
  });

  /// Stops the playback instance identified by [handle].
  void stop(int handle);

  /// Sets the volume for a specific playback instance or sound.
  void setVolume(int handleOrSoundId, double volume);

  /// Sets the pan for a specific playback instance or sound.
  void setPan(int handleOrSoundId, double pan);

  /// Disposes of the audio backend and releases all resources.
  void dispose();
}

/// A null implementation of [AudioBackend] that does nothing.
/// Useful as a fallback or for headless/testing environments.
class NullAudioBackend implements AudioBackend {
  int _nextHandle = 1;

  @override
  Future<void> init() async {}

  @override
  Future<void> loadSound(int soundId, String path) async {}

  @override
  void unloadSound(int soundId) {}

  @override
  int play(
    int soundId, {
    double volume = 1.0,
    double pitch = 1.0,
    bool loop = false,
  }) {
    return _nextHandle++;
  }

  @override
  void stop(int handle) {}

  @override
  void setVolume(int handleOrSoundId, double volume) {}

  @override
  void setPan(int handleOrSoundId, double pan) {}

  @override
  void dispose() {}
}
