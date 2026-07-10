import 'dart:typed_data';

/// A flat WorldUI component using a Dart extension type over a Float32List.
/// Connects a world entity to a target UI entity and specifies offsets.
/// Index 0: targetUiEntityId, Index 1: offsetX, Index 2: offsetY
extension type WorldUI(Float32List data) {
  /// Creates a new WorldUI component mapping to [targetUiEntityId].
  WorldUI.create(double targetUiEntityId, [double offsetX = 0.0, double offsetY = 0.0])
      : this(Float32List(3)
          ..[0] = targetUiEntityId
          ..[1] = offsetX
          ..[2] = offsetY);

  /// Gets the ID of the UI entity (usually a ComplexUI) to update.
  double get targetUiEntityId => data[0];
  set targetUiEntityId(double value) => data[0] = value;

  /// Gets the horizontal offset from the entity's position.
  double get offsetX => data[1];
  set offsetX(double value) => data[1] = value;

  /// Gets the vertical offset from the entity's position.
  double get offsetY => data[2];
  set offsetY(double value) => data[2] = value;
}
