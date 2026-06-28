import 'dart:typed_data';
import 'package:sting/engine/audio/audio_event_queue.dart';
import 'package:sting/engine/audio/audio_bindings.dart';

/// The AudioSystem processes audio events from an AudioEventQueue
/// and tracks active audio playback.
class AudioSystem {
  final AudioEventQueue _queue;

  // Track active sounds: stores pairs of [playbackHandle, entityId]
  final Int32List _activeSounds;
  int _activeCount = 0;

  AudioSystem(this._queue, {int maxActiveSounds = 64})
      : _activeSounds = Int32List(maxActiveSounds * 2);

  int get activeSoundCount => _activeCount;

  void update() {
    _queue.process((int soundId, int entityId) {
      if (_activeCount < _activeSounds.length ~/ 2) {
        // Call low-level bindings
        final handle = AudioBindings.play(soundId);
        if (handle > 0) {
          final index = _activeCount * 2;
          _activeSounds[index] = handle;
          _activeSounds[index + 1] = entityId;
          _activeCount++;
        }
      }
    });
  }

  void clearActiveSounds() {
    for (int i = 0; i < _activeCount; i++) {
      AudioBindings.stop(_activeSounds[i * 2]);
    }
    _activeCount = 0;
  }

  // Get active sound info at a given dense index for testing
  int getActiveHandle(int index) => _activeSounds[index * 2];
  int getActiveEntityId(int index) => _activeSounds[index * 2 + 1];
}
