import 'dart:typed_data';

/// A flat ParticleEmitter component using a Dart extension type over ByteData.
/// This packs the emitter metadata and the particle state data (positions, velocities,
/// colors, lifespans) into a contiguous chunk of memory to avoid GC allocations.
///
/// Memory layout (Header - 24 bytes):
/// - 0..3: maxParticles (int32)
/// - 4..7: activeParticles (int32)
/// - 8..11: emitRate (float32) - Particles emitted per second
/// - 12..15: accumulator (float32) - Time accumulator for emitting particles
/// - 16..23: reserved
///
/// Particle Data Layout (28 bytes per particle starting at byte 24):
/// - 0..3: x (float32)
/// - 4..7: y (float32)
/// - 8..11: dx (float32)
/// - 12..15: dy (float32)
/// - 16..19: life (float32) - Current lifetime in seconds
/// - 20..23: maxLife (float32) - Maximum lifetime in seconds
/// - 24..27: color (uint32) - ARGB color representation
extension type ParticleEmitter(ByteData data) {
  /// Creates a new ParticleEmitter component with the specified maximum number of particles.
  ParticleEmitter.create(int maxParticles)
      : this(ByteData(24 + maxParticles * 28)..setInt32(0, maxParticles, Endian.little));

  /// The maximum number of particles this emitter can manage.
  int get maxParticles => data.getInt32(0, Endian.little);

  /// The current number of active particles.
  int get activeParticles => data.getInt32(4, Endian.little);

  /// Sets the number of active particles.
  set activeParticles(int value) => data.setInt32(4, value, Endian.little);

  /// The number of particles to emit per second.
  double get emitRate => data.getFloat32(8, Endian.little);

  /// Sets the number of particles to emit per second.
  set emitRate(double value) => data.setFloat32(8, value, Endian.little);

  /// The time accumulator used to determine when to emit new particles.
  double get accumulator => data.getFloat32(12, Endian.little);

  /// Sets the time accumulator.
  set accumulator(double value) => data.setFloat32(12, value, Endian.little);

  // --- Particle Data Accessors ---

  double getParticleX(int index) => data.getFloat32(24 + index * 28 + 0, Endian.little);
  void setParticleX(int index, double value) => data.setFloat32(24 + index * 28 + 0, value, Endian.little);

  double getParticleY(int index) => data.getFloat32(24 + index * 28 + 4, Endian.little);
  void setParticleY(int index, double value) => data.setFloat32(24 + index * 28 + 4, value, Endian.little);

  double getParticleDx(int index) => data.getFloat32(24 + index * 28 + 8, Endian.little);
  void setParticleDx(int index, double value) => data.setFloat32(24 + index * 28 + 8, value, Endian.little);

  double getParticleDy(int index) => data.getFloat32(24 + index * 28 + 12, Endian.little);
  void setParticleDy(int index, double value) => data.setFloat32(24 + index * 28 + 12, value, Endian.little);

  double getParticleLife(int index) => data.getFloat32(24 + index * 28 + 16, Endian.little);
  void setParticleLife(int index, double value) => data.setFloat32(24 + index * 28 + 16, value, Endian.little);

  double getParticleMaxLife(int index) => data.getFloat32(24 + index * 28 + 20, Endian.little);
  void setParticleMaxLife(int index, double value) => data.setFloat32(24 + index * 28 + 20, value, Endian.little);

  int getParticleColor(int index) => data.getUint32(24 + index * 28 + 24, Endian.little);
  void setParticleColor(int index, int value) => data.setUint32(24 + index * 28 + 24, value, Endian.little);
}
