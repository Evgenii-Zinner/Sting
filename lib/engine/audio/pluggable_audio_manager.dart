import 'package:sting/engine/systems/audio_spatial_system.dart';
import 'package:sting/engine/audio/audio_backend.dart';

/// An [AudioManager] implementation that delegates to a swappable [AudioBackend].
/// By default, it uses a [NullAudioBackend].
class PluggableAudioManager implements AudioManager {
  AudioBackend _backend;

  PluggableAudioManager({AudioBackend? backend})
      : _backend = backend ?? NullAudioBackend();

  /// Gets the currently active audio backend.
  AudioBackend get backend => _backend;

  /// Swaps the active audio backend.
  void setBackend(AudioBackend newBackend) {
    _backend = newBackend;
  }

  @override
  void setVolume(int soundId, double volume) {
    _backend.setVolume(soundId, volume);
  }

  @override
  void setPan(int soundId, double pan) {
    _backend.setPan(soundId, pan);
  }
}
