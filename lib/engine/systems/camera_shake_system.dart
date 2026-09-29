import 'dart:math';
import '../components/camera_trauma.dart';
import '../components/viewport.dart';
import '../ecs/component_caste.dart';

class CameraShakeSystem {
  final ComponentCaste<CameraTrauma> cameraTraumaCaste;
  final ComponentCaste<Viewport> viewportCaste;

  double _time = 0.0;

  CameraShakeSystem({
    required this.cameraTraumaCaste,
    required this.viewportCaste,
  });

  /// Updates the trauma and applies shake to the camera viewport based on [dt] (delta time).
  /// This should be called before rendering, after the camera target has been set.
  void update(List<int> entities, double dt) {
    _time += dt;

    for (final entity in entities) {
      final traumaComponent = cameraTraumaCaste.get(entity);
      final viewport = viewportCaste.get(entity);

      if (traumaComponent == null || viewport == null) {
        continue;
      }

      if (traumaComponent.trauma <= 0.0) {
        continue;
      }

      // Decay trauma linearly (setter handles clamping to 0.0 and 1.0)
      traumaComponent.trauma -= traumaComponent.decayRate * dt;

      // Calculate shake intensity (trauma^2 for organic feel)
      final shake = traumaComponent.trauma * traumaComponent.trauma;

      if (shake > 0.0) {
        // Simple pseudo-random noise function (zero allocations)
        double offsetX = traumaComponent.maxTranslationX * shake * _pseudoNoise(_time * traumaComponent.frequency, 1);
        double offsetY = traumaComponent.maxTranslationY * shake * _pseudoNoise(_time * traumaComponent.frequency, 2);
        double rotation = traumaComponent.maxRotation * shake * _pseudoNoise(_time * traumaComponent.frequency, 3);

        viewport.x += offsetX;
        viewport.y += offsetY;
        viewport.angle += rotation;
      }
    }
  }

  /// Updates a single entity. Note that calling this multiple times per frame
  /// will advance the internal time multiple times. Use `update` with a list of entities instead for
  /// multiple entities if they need to share the same clock.
  void updateEntity(int entity, double dt) {
    _time += dt;
    final traumaComponent = cameraTraumaCaste.get(entity);
    final viewport = viewportCaste.get(entity);

    if (traumaComponent == null || viewport == null) {
      return;
    }

    if (traumaComponent.trauma <= 0.0) {
      return;
    }

    // Decay trauma linearly (setter handles clamping to 0.0 and 1.0)
    traumaComponent.trauma -= traumaComponent.decayRate * dt;

    // Calculate shake intensity (trauma^2 for organic feel)
    final shake = traumaComponent.trauma * traumaComponent.trauma;

    if (shake > 0.0) {
      // Simple pseudo-random noise function (zero allocations)
      double offsetX = traumaComponent.maxTranslationX * shake * _pseudoNoise(_time * traumaComponent.frequency, 1);
      double offsetY = traumaComponent.maxTranslationY * shake * _pseudoNoise(_time * traumaComponent.frequency, 2);
      double rotation = traumaComponent.maxRotation * shake * _pseudoNoise(_time * traumaComponent.frequency, 3);

      viewport.x += offsetX;
      viewport.y += offsetY;
      viewport.angle += rotation;
    }
  }

  // A simple pseudo-random noise function from -1 to 1 based on time and an offset.
  double _pseudoNoise(double t, int offset) {
    return sin(t + offset * 12.345) * cos(t * 1.5 + offset * 3.1415);
  }
}
