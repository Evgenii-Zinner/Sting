import 'dart:typed_data';

/// A flat ParticleEmitter component using a Dart extension type over ByteData.
/// This packs the emitter metadata and the particle state data (positions, velocities,
/// colors, lifespans, scale) into a contiguous chunk of memory to avoid GC allocations.
///
/// Memory layout (Header - 48 bytes):
/// - 0..3: maxParticles (int32)
/// - 4..7: activeParticles (int32)
/// - 8..11: emitRate (float32) - Particles emitted per second
/// - 12..15: accumulator (float32) - Time accumulator for emitting particles
/// - 16..19: startColor (uint32) - ARGB start color
/// - 20..23: endColor (uint32) - ARGB end color
/// - 24..27: startScale (float32) - Starting scale of particles
/// - 28..31: midScale (float32) - Middle scale of particles
/// - 32..35: endScale (float32) - Ending scale of particles
/// - 36..39: midScaleRatio (float32) - Ratio (0.0 to 1.0) when midScale is reached
/// - 40..47: reserved
///
/// Particle Data Layout (32 bytes per particle starting at byte 48):
/// - 0..3: x (float32)
/// - 4..7: y (float32)
/// - 8..11: dx (float32)
/// - 12..15: dy (float32)
/// - 16..19: life (float32) - Current lifetime in seconds
/// - 20..23: maxLife (float32) - Maximum lifetime in seconds
/// - 24..27: color (uint32) - ARGB color representation
/// - 28..31: scale (float32) - Current scale of the particle
extension type ParticleEmitter(ByteData data) {
  /// Creates a new ParticleEmitter component with the specified maximum number of particles.
  ParticleEmitter.create(int maxParticles)
      : this(ByteData(48 + maxParticles * 32)
          ..setInt32(0, maxParticles, Endian.little)
          ..setUint32(16, 0xFFFFFFFF, Endian.little) // default startColor
          ..setUint32(20, 0xFFFFFFFF, Endian.little) // default endColor
          ..setFloat32(24, 1.0, Endian.little) // default startScale
          ..setFloat32(28, 1.0, Endian.little) // default midScale
          ..setFloat32(32, 1.0, Endian.little) // default endScale
          ..setFloat32(36, 0.5, Endian.little)); // default midScaleRatio

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

  int get startColor => data.getUint32(16, Endian.little);
  set startColor(int value) => data.setUint32(16, value, Endian.little);

  int get endColor => data.getUint32(20, Endian.little);
  set endColor(int value) => data.setUint32(20, value, Endian.little);

  double get startScale => data.getFloat32(24, Endian.little);
  set startScale(double value) => data.setFloat32(24, value, Endian.little);

  double get midScale => data.getFloat32(28, Endian.little);
  set midScale(double value) => data.setFloat32(28, value, Endian.little);

  double get endScale => data.getFloat32(32, Endian.little);
  set endScale(double value) => data.setFloat32(32, value, Endian.little);

  double get midScaleRatio => data.getFloat32(36, Endian.little);
  set midScaleRatio(double value) => data.setFloat32(36, value, Endian.little);

  // --- Particle Data Accessors ---
  // Particle Data offset: 48, size: 32

  double getParticleX(int index) =>
      data.getFloat32(48 + index * 32 + 0, Endian.little);
  void setParticleX(int index, double value) =>
      data.setFloat32(48 + index * 32 + 0, value, Endian.little);

  double getParticleY(int index) =>
      data.getFloat32(48 + index * 32 + 4, Endian.little);
  void setParticleY(int index, double value) =>
      data.setFloat32(48 + index * 32 + 4, value, Endian.little);

  double getParticleDx(int index) =>
      data.getFloat32(48 + index * 32 + 8, Endian.little);
  void setParticleDx(int index, double value) =>
      data.setFloat32(48 + index * 32 + 8, value, Endian.little);

  double getParticleDy(int index) =>
      data.getFloat32(48 + index * 32 + 12, Endian.little);
  void setParticleDy(int index, double value) =>
      data.setFloat32(48 + index * 32 + 12, value, Endian.little);

  double getParticleLife(int index) =>
      data.getFloat32(48 + index * 32 + 16, Endian.little);
  void setParticleLife(int index, double value) =>
      data.setFloat32(48 + index * 32 + 16, value, Endian.little);

  double getParticleMaxLife(int index) =>
      data.getFloat32(48 + index * 32 + 20, Endian.little);
  void setParticleMaxLife(int index, double value) =>
      data.setFloat32(48 + index * 32 + 20, value, Endian.little);

  int getParticleColor(int index) =>
      data.getUint32(48 + index * 32 + 24, Endian.little);
  void setParticleColor(int index, int value) =>
      data.setUint32(48 + index * 32 + 24, value, Endian.little);

  double getParticleScale(int index) =>
      data.getFloat32(48 + index * 32 + 28, Endian.little);
  void setParticleScale(int index, double value) =>
      data.setFloat32(48 + index * 32 + 28, value, Endian.little);
}
