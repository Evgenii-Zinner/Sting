import 'dart:typed_data';

/// A flat EnemyAI component using a Dart extension type over a Float32List.
/// Index 0: targetId (cast to double).
/// We need target tracking but no per-frame allocations.
extension type EnemyAI(Float32List data) {
  /// Creates a new EnemyAI component.
  EnemyAI.create(int targetId)
      : this(Float32List(1)..[0] = targetId.toDouble());

  /// Gets the target entity ID.
  int get targetId => data[0].toInt();

  /// Sets the target entity ID.
  set targetId(int value) => data[0] = value.toDouble();
}
