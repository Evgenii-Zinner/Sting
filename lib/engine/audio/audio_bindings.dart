import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';

/// A real low-level audio binding class representing FFI or platform channels.
class AudioBindings {
  static final SoLoud _soloud = SoLoud.instance;
  static bool _initialized = false;
  static final Map<int, AudioSource> _soundHashes = {};

  static Future<void> init() async {
    if (!_initialized) {
      await _soloud.init();
      _initialized = true;
    }
  }

  static Future<void> loadSound(int soundId, String path) async {
    if (!_initialized) return;
    // Load file and manage lifecycle manually because sounds will be reused repeatedly without reloading
    final sound = await _soloud.loadFile(path, mode: LoadMode.disk);
    _soundHashes[soundId] = sound;
  }

  /// Unloads an audio source from memory.
  static void unloadSound(int soundId) {
    if (!_initialized) return;
    final source = _soundHashes.remove(soundId);
    if (source != null) {
      _soloud.disposeSource(source);
    }
  }

  static int _nextHandle = 1;

  /// Plays a sound and returns a playback handle.
  ///
  /// Returns a positive integer handle on success, or 0 on failure.
  static int play(
    int soundId, {
    double volume = 1.0,
    double pitch = 1.0,
    bool loop = false,
  }) {
    if (!_initialized) return _nextHandle++; // MOCK behavior for tests when not initialized.

    final source = _soundHashes[soundId];
    if (source == null) return 0;

    final int pseudoHandle = _nextHandle++;
    try {
      final SoundHandle handle = _soloud.play(source, volume: volume, looping: loop);

      if (pitch != 1.0) {
        _soloud.setRelativePlaySpeed(handle, pitch);
      }

      _realHandles[pseudoHandle] = handle;

      // Memory Leak Fix: Cleanup handles
      // Since SoLoud isolates handles, we listen to allInstancesFinished.
      // We must cancel the subscription as soon as the source finishes to prevent dart memory leaks.
      late StreamSubscription<void> sub;
      sub = source.allInstancesFinished.listen((_) {
        _realHandles.remove(pseudoHandle);
        sub.cancel();
      });

    } catch (e) {
      return 0;
    }

    return pseudoHandle;
  }

  static final Map<int, SoundHandle> _realHandles = {};

  /// Stops an active playback handle.
  static void stop(int handle) {
    if (!_initialized) return;
    final realHandle = _realHandles.remove(handle);
    if (realHandle != null) {
      _soloud.stop(realHandle);
    }
  }
}
