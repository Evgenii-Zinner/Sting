import 'dart:typed_data';

/// A flat EntityFSM component using a Dart extension type over a ByteData.
/// Stores state machine data for an entity with zero allocations.
///
/// Byte Offsets:
/// 0: currentState (Int32)
/// 4: previousState (Int32)
/// 8: stateTimer (Float32)
/// 12: flags (Int32)
extension type EntityFSM(ByteData data) {
  static const int sizeInBytes = 16;

  /// Creates a new EntityFSM component.
  EntityFSM.create({
    int currentState = 0,
    int previousState = 0,
    double stateTimer = 0.0,
    int flags = 0,
  }) : this(ByteData(sizeInBytes)
          ..setInt32(0, currentState, Endian.host)
          ..setInt32(4, previousState, Endian.host)
          ..setFloat32(8, stateTimer, Endian.host)
          ..setInt32(12, flags, Endian.host));

  int get currentState => data.getInt32(0, Endian.host);
  set currentState(int value) => data.setInt32(0, value, Endian.host);

  int get previousState => data.getInt32(4, Endian.host);
  set previousState(int value) => data.setInt32(4, value, Endian.host);

  double get stateTimer => data.getFloat32(8, Endian.host);
  set stateTimer(double value) => data.setFloat32(8, value, Endian.host);

  int get flags => data.getInt32(12, Endian.host);
  set flags(int value) => data.setInt32(12, value, Endian.host);

  /// Changes the current state to [newState].
  /// Updates [previousState] to the current state and resets [stateTimer] to 0.0.
  void changeState(int newState) {
    previousState = currentState;
    currentState = newState;
    stateTimer = 0.0;
  }
}
