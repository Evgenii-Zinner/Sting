import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/particle_emitter.dart';
import 'package:sting/engine/systems/particle_system.dart';

void main() {
  test('ParticleSystem updates lifetimes and physics', () {
    final positions = ComponentStorage<Position>(100);
    final emitters = ComponentStorage<ParticleEmitter>(100);

    final entity = 1;
    positions.add(entity, Position.create(100.0, 100.0));

    final emitter = ParticleEmitter.create(10);
    emitter.emitRate = 0; // Don't emit new particles automatically
    emitter.activeParticles = 1;
    emitter.setParticleX(0, 100.0);
    emitter.setParticleY(0, 100.0);
    emitter.setParticleDx(0, 10.0);
    emitter.setParticleDy(0, 0.0);
    emitter.setParticleLife(0, 1.0);
    emitter.setParticleMaxLife(0, 1.0);

    // Set some test values for scale and color
    emitter.startColor = 0xFF000000;
    emitter.endColor = 0xFFFFFFFF;
    emitter.startScale = 1.0;
    emitter.midScale = 2.0;
    emitter.endScale = 3.0;
    emitter.midScaleRatio = 0.5;

    emitters.add(entity, emitter);

    // We can use a null-ish Image for tests that don't call render if dart allows,
    // but the system requires an Image.
    // We'll skip testing the drawRawAtlas exact path since we can't instantiate a real Image synchronously.

    final system = ParticleSystem(positions, emitters, null as dynamic,
        const ui.Rect.fromLTWH(0, 0, 10, 10));

    system.update(0.5);

    expect(emitter.getParticleLife(0), closeTo(0.5, 0.001));
    expect(emitter.getParticleX(0), closeTo(105.0, 0.001));
    expect(emitter.getParticleY(0), closeTo(100.0, 0.001));

    // Scale and Color interpolation checks
    // Life ratio is 1.0 - (0.5 / 1.0) = 0.5
    // Scale at 0.5 (midScaleRatio) should be exactly midScale (2.0)
    expect(emitter.getParticleScale(0), closeTo(2.0, 0.001));
    // Color should be roughly mid gray
    expect(emitter.getParticleColor(0), 0xFF808080);

    system.update(0.25);
    // Life is 0.25. Ratio is 0.75
    // Scale at 0.75 (between midScaleRatio 0.5 and 1.0) -> midScale + (endScale - midScale) * ((0.75 - 0.5) / 0.5)
    // 2.0 + 1.0 * 0.5 = 2.5
    expect(emitter.getParticleScale(0), closeTo(2.5, 0.001));
    // Color should be mostly white
    expect(emitter.getParticleColor(0), 0xFFBFBFBF);

    system.update(0.35); // 0.25 - 0.35 = -0.1 < 0 -> dead

    expect(emitter.activeParticles, 0);
  });

  test('ParticleSystem handles scale correctly with edge case midScaleRatios',
      () {
    final positions = ComponentStorage<Position>(100);
    final emitters = ComponentStorage<ParticleEmitter>(100);

    final entity = 1;
    positions.add(entity, Position.create(100.0, 100.0));

    final emitter = ParticleEmitter.create(10);
    emitter.emitRate = 0;
    emitter.activeParticles = 1;
    emitter.setParticleLife(0, 1.0);
    emitter.setParticleMaxLife(0, 1.0);

    emitter.startScale = 1.0;
    emitter.midScale = 2.0;
    emitter.endScale = 3.0;
    emitter.midScaleRatio = 0.0; // edge case: ratio is 0.0

    emitters.add(entity, emitter);

    final system = ParticleSystem(positions, emitters, null as dynamic,
        const ui.Rect.fromLTWH(0, 0, 10, 10));

    system.update(0.5); // ratio = 0.5
    // Because midScaleRatio is 0.0, it should use the second half of the piecewise curve
    // Scale at 0.5 -> midScale + (endScale - midScale) * ((0.5 - 0.0) / 1.0) -> 2.0 + 1.0 * 0.5 = 2.5
    expect(emitter.getParticleScale(0), closeTo(2.5, 0.001));

    emitter.midScaleRatio = 1.0; // edge case: ratio is 1.0
    emitter.setParticleLife(0, 1.0); // Reset life
    system.update(0.5); // ratio = 0.5
    // Because midScaleRatio is 1.0, it should use the first half
    // Scale at 0.5 -> startScale + (midScale - startScale) * (0.5 / 1.0) -> 1.0 + 1.0 * 0.5 = 1.5
    expect(emitter.getParticleScale(0), closeTo(1.5, 0.001));
  });

  test('ParticleSystem emits particles over time', () {
    final positions = ComponentStorage<Position>(100);
    final emitters = ComponentStorage<ParticleEmitter>(100);

    final entity = 1;
    positions.add(entity, Position.create(100.0, 100.0));

    final emitter = ParticleEmitter.create(10);
    emitter.emitRate = 10; // 10 particles per second -> 1 particle every 0.1s
    emitter.activeParticles = 0;

    emitters.add(entity, emitter);

    final system = ParticleSystem(positions, emitters, null as dynamic,
        const ui.Rect.fromLTWH(0, 0, 10, 10));

    system.update(0.25); // Should emit 2 particles (0.1, 0.2)

    expect(emitter.activeParticles, 2);
    expect(emitter.accumulator, closeTo(0.05, 0.001));
  });

  test('ParticleSystem rendering - ensure buffers are sub-viewed correctly',
      () async {
    // Create a 1x1 image for testing
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvasForImage = ui.Canvas(recorder);
    canvasForImage.drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    final ui.Image image = await recorder.endRecording().toImage(1, 1);

    final positions = ComponentStorage<Position>(100);
    final emitters = ComponentStorage<ParticleEmitter>(100);

    final entity = 1;
    positions.add(entity, Position.create(100.0, 100.0));

    final emitter = ParticleEmitter.create(10);
    emitter.emitRate = 10;
    emitter.activeParticles = 0;

    emitters.add(entity, emitter);

    final system = ParticleSystem(
        positions, emitters, image, const ui.Rect.fromLTWH(0, 0, 1, 1));

    system.update(0.25);

    final renderRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(renderRecorder);
    final paint = ui.Paint();

    expect(() => system.render(canvas, paint), returnsNormally);
  });
}
