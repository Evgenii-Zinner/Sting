import 'dart:ui';
import 'dart:typed_data';
import 'dart:math';

import '../ecs/component_caste.dart';
import '../components/position.dart';
import '../components/particle_emitter.dart';

/// A system that manages particle lifespans, physics updates, and rendering.
/// Ensures zero per-frame object allocations.
class ParticleSystem {
  final ComponentCaste<Position> positions;
  final ComponentCaste<ParticleEmitter> emitters;
  final Random _random = Random();

  // Pre-allocated buffers for Canvas.drawRawAtlas
  final Float32List _transformBuffer;
  final Float32List _rectBuffer;
  final Int32List _colorBuffer;

  /// The shared texture to use for drawing particles.
  final Image? particleImage;

  /// The source rectangle in the [particleImage] for a single particle.
  final Rect particleSourceRect;

  /// Creates a ParticleSystem capable of rendering up to [maxTotalParticles]
  /// concurrently without allocating new memory buffers.
  ParticleSystem(this.positions, this.emitters, this.particleImage, this.particleSourceRect, {int maxTotalParticles = 65535})
      : _transformBuffer = Float32List(maxTotalParticles * 4), // scos, ssin, tx, ty
        _rectBuffer = Float32List(maxTotalParticles * 4), // l, t, r, b
        _colorBuffer = Int32List(maxTotalParticles);

  /// Updates particle lifetimes, physics, and emissions.
  void update(double dt) {
    for (int i = 0; i < emitters.length; i++) {
      final entity = emitters.elementAt(i);
      final pos = positions.get(entity);
      if (pos == null) continue;

      final emitter = emitters.get(entity)!;

      // Update existing particles
      int active = emitter.activeParticles;
      for (int p = 0; p < active; p++) {
        double life = emitter.getParticleLife(p);
        life -= dt;

        if (life <= 0) {
          active--;
          if (p < active) {
             emitter.setParticleX(p, emitter.getParticleX(active));
             emitter.setParticleY(p, emitter.getParticleY(active));
             emitter.setParticleDx(p, emitter.getParticleDx(active));
             emitter.setParticleDy(p, emitter.getParticleDy(active));
             emitter.setParticleLife(p, emitter.getParticleLife(active));
             emitter.setParticleMaxLife(p, emitter.getParticleMaxLife(active));
             emitter.setParticleColor(p, emitter.getParticleColor(active));
          }
          p--;
          continue;
        }

        // Apply kinematics
        double x = emitter.getParticleX(p);
        double y = emitter.getParticleY(p);
        double dx = emitter.getParticleDx(p);
        double dy = emitter.getParticleDy(p);

        emitter.setParticleX(p, x + dx * dt);
        emitter.setParticleY(p, y + dy * dt);
        emitter.setParticleLife(p, life);
      }

      // Emit new particles
      if (emitter.emitRate > 0) {
        double acc = emitter.accumulator + dt;
        double emitInterval = 1.0 / emitter.emitRate;
        int maxP = emitter.maxParticles;

        while (acc >= emitInterval && active < maxP) {
          acc -= emitInterval;

          emitter.setParticleX(active, pos.x);
          emitter.setParticleY(active, pos.y);

          double angle = _random.nextDouble() * 2 * pi;
          double speed = 50.0 + _random.nextDouble() * 100.0;
          emitter.setParticleDx(active, cos(angle) * speed);
          emitter.setParticleDy(active, sin(angle) * speed);

          emitter.setParticleLife(active, 1.0);
          emitter.setParticleMaxLife(active, 1.0);
          emitter.setParticleColor(active, 0xFFFFFFFF);

          active++;
        }
        emitter.accumulator = acc;
      }

      emitter.activeParticles = active;
    }
  }

  /// Renders all particles efficiently.
  void render(Canvas canvas, Paint paint) {
    if (particleImage == null) return;
    int totalParticlesToDraw = 0;

    for (int i = 0; i < emitters.length; i++) {
      final entity = emitters.elementAt(i);
      final pos = positions.get(entity);
      if (pos == null) continue;

      final emitter = emitters.get(entity)!;
      final active = emitter.activeParticles;

      for (int p = 0; p < active; p++) {
        if (totalParticlesToDraw >= _colorBuffer.length) {
            break;
        }

        final idx = totalParticlesToDraw * 4;

        // Transform: scos, ssin, tx, ty
        _transformBuffer[idx + 0] = 1.0; // scale X * cos(0)
        _transformBuffer[idx + 1] = 0.0; // scale Y * sin(0)
        _transformBuffer[idx + 2] = emitter.getParticleX(p);
        _transformBuffer[idx + 3] = emitter.getParticleY(p);

        // Rect: left, top, right, bottom
        _rectBuffer[idx + 0] = particleSourceRect.left;
        _rectBuffer[idx + 1] = particleSourceRect.top;
        _rectBuffer[idx + 2] = particleSourceRect.right;
        _rectBuffer[idx + 3] = particleSourceRect.bottom;

        // Color
        _colorBuffer[totalParticlesToDraw] = emitter.getParticleColor(p);

        totalParticlesToDraw++;
      }
    }

    if (totalParticlesToDraw > 0) {
        final transformView = Float32List.sublistView(_transformBuffer, 0, totalParticlesToDraw * 4);
        final rectView = Float32List.sublistView(_rectBuffer, 0, totalParticlesToDraw * 4);
        final colorView = Int32List.sublistView(_colorBuffer, 0, totalParticlesToDraw);

        canvas.drawRawAtlas(
           particleImage!,
           transformView,
           rectView,
           colorView,
           BlendMode.srcOver, // or modualte/screen based on particle config
           null,
           paint
        );
    }
  }
}
