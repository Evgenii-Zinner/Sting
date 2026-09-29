import 'dart:math' as math;
import 'package:sting/engine/components/audio_emitter.dart';
import 'package:sting/engine/components/audio_listener.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/ecs/query.dart';

/// Abstract interface for audio management to allow mockability and
/// integration with different audio backends (e.g., SoLoud).
abstract class AudioManager {
  /// Sets the volume of the sound identified by [soundId].
  /// Volume is typically in the range [0.0, 1.0].
  void setVolume(int soundId, double volume);

  /// Sets the pan of the sound identified by [soundId].
  /// Pan is typically in the range [-1.0, 1.0].
  void setPan(int soundId, double pan);
}

/// A system that computes distance-based volume attenuation and stereo panning
/// for AudioEmitters relative to an active AudioListener.
///
/// It relies on an external [AudioManager] to apply the computed values.
class AudioSpatialSystem {
  final AudioManager audioManager;
  final Query2<Position, AudioListener> listenerQuery;
  final Query2<Position, AudioEmitter> emitterQuery;

  AudioSpatialSystem({
    required this.audioManager,
    required this.listenerQuery,
    required this.emitterQuery,
  });

  /// Updates the spatial audio properties for all emitters.
  ///
  /// Achieves zero heap allocations during the update loop.
  void update() {
    double listenerX = 0.0;
    double listenerY = 0.0;
    double hearingRange = 0.0;
    double masterVolume = 0.0;
    bool hasListener = false;

    // Find the first active listener
    listenerQuery.forEach((entity, pos, listener) {
      if (!hasListener) {
        listenerX = pos.x;
        listenerY = pos.y;
        hearingRange = listener.hearingRange;
        masterVolume = listener.masterVolume;
        hasListener = true;
      }
    });

    if (!hasListener) {
      return; // No active listener, nothing to update
    }

    // Process all emitters
    emitterQuery.forEach((entity, pos, emitter) {
      if (!emitter.isPlaying) {
        return;
      }

      final dx = pos.x - listenerX;
      final dy = pos.y - listenerY;
      final distanceSq = dx * dx + dy * dy;
      final distance = math.sqrt(distanceSq);

      if (distance > emitter.maxDistance || distance > hearingRange) {
        audioManager.setVolume(emitter.soundId, 0.0);
        return;
      }

      // Calculate distance attenuation (inverse distance model)
      double attenuation = 1.0;
      if (distance > emitter.referenceDistance) {
        attenuation = emitter.referenceDistance /
            (emitter.referenceDistance +
                emitter.rolloffFactor * (distance - emitter.referenceDistance));
      }

      // Clamp attenuation
      if (attenuation < 0.0) attenuation = 0.0;
      if (attenuation > 1.0) attenuation = 1.0;

      final finalVolume = attenuation * emitter.volume * masterVolume;
      audioManager.setVolume(emitter.soundId, finalVolume);

      // Calculate stereo pan based on relative X distance
      double pan = 0.0;
      if (emitter.maxDistance > 0.0) {
        pan = dx / emitter.maxDistance;
      }

      if (pan < -1.0) pan = -1.0;
      if (pan > 1.0) pan = 1.0;

      audioManager.setPan(emitter.soundId, pan);
    });
  }
}
