import 'dart:typed_data';
import 'package:sting/engine/audio/audio_event_queue.dart';
import 'package:sting/engine/audio/audio_bindings.dart';

/// Processes audio playback events from [AudioEventQueue] and tracks active audio channels.
class AudioSystem {
  final AudioEventQueue _queue;

  // Track active sounds: stores pairs of [playbackHandle, entityId]
  final Int32List _activeSounds;
  int _activeCount = 0;

  /// Creates a new [AudioSystem] monitoring [_queue].
  AudioSystem(this._queue, {int maxActiveSounds = 64})
      : _activeSounds = Int32List(maxActiveSounds * 2);

  /// Number of actively playing audio instances.
  int get activeSoundCount => _activeCount;

  /// Flushes pending audio events from the event queue and issues playback requests.
  void update() {
    _queue.process((
      int soundId,
      int entityId,
      double volume,
      double pitch,
      bool loop,
    ) {
      if (_activeCount < _activeSounds.length ~/ 2) {
        // Call low-level bindings
        final handle = AudioBindings.play(
          soundId,
          volume: volume,
          pitch: pitch,
          loop: loop,
        );
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
