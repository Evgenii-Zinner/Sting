import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/particle_emitter.dart';

void main() {
  test('ParticleEmitter basic creation and field access', () {
    final emitter = ParticleEmitter.create(100);

    expect(emitter.maxParticles, 100);
    expect(emitter.activeParticles, 0);

    emitter.activeParticles = 50;
    expect(emitter.activeParticles, 50);

    emitter.emitRate = 10.5;
    expect(emitter.emitRate, closeTo(10.5, 0.001));

    emitter.accumulator = 0.25;
    expect(emitter.accumulator, closeTo(0.25, 0.001));
  });

  test('ParticleEmitter sets and gets particle data correctly', () {
    final emitter = ParticleEmitter.create(10);

    emitter.setParticleX(5, 123.45);
    expect(emitter.getParticleX(5), closeTo(123.45, 0.001));

    emitter.setParticleY(5, 678.90);
    expect(emitter.getParticleY(5), closeTo(678.90, 0.001));

    emitter.setParticleDx(5, -12.3);
    expect(emitter.getParticleDx(5), closeTo(-12.3, 0.001));

    emitter.setParticleDy(5, 45.6);
    expect(emitter.getParticleDy(5), closeTo(45.6, 0.001));

    emitter.setParticleLife(5, 0.5);
    expect(emitter.getParticleLife(5), closeTo(0.5, 0.001));

    emitter.setParticleMaxLife(5, 1.0);
    expect(emitter.getParticleMaxLife(5), closeTo(1.0, 0.001));

    emitter.setParticleColor(5, 0x12345678);
    expect(emitter.getParticleColor(5), 0x12345678);
  });
}
