import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/particle_emitter.dart';
import 'package:sting/engine/systems/particle_system.dart';

void main() {
  test('ParticleSystem updates lifetimes and physics', () {
    final positions = ComponentCaste<Position>(100);
    final emitters = ComponentCaste<ParticleEmitter>(100);

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

    system.update(0.6); // 0.5 - 0.6 = -0.1 < 0 -> dead

    expect(emitter.activeParticles, 0);
  });

  test('ParticleSystem emits particles over time', () {
    final positions = ComponentCaste<Position>(100);
    final emitters = ComponentCaste<ParticleEmitter>(100);

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

    final positions = ComponentCaste<Position>(100);
    final emitters = ComponentCaste<ParticleEmitter>(100);

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
