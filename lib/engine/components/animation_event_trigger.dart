import 'dart:typed_data';

/// A flat AnimationEventTrigger component using a Dart extension type over an Int32List.
/// Index 0: targetFrame
/// Index 1: eventId
/// Index 2: triggerOnce (0 = false, 1 = true)
/// Index 3: hasTriggered (0 = false, 1 = true)
extension type AnimationEventTrigger(Int32List data) {
  /// Creates a new AnimationEventTrigger component with the given parameters.
  AnimationEventTrigger.create(
    int targetFrame,
    int eventId, {
    bool triggerOnce = false,
  }) : this(Int32List(4)
          ..[0] = targetFrame
          ..[1] = eventId
          ..[2] = triggerOnce ? 1 : 0
          ..[3] = 0);

  /// Gets the target frame index.
  int get targetFrame => data[0];

  /// Sets the target frame index.
  set targetFrame(int value) => data[0] = value;

  /// Gets the event ID.
  int get eventId => data[1];

  /// Sets the event ID.
  set eventId(int value) => data[1] = value;

  /// Gets whether this trigger should only fire once.
  bool get triggerOnce => data[2] != 0;

  /// Sets whether this trigger should only fire once.
  set triggerOnce(bool value) => data[2] = value ? 1 : 0;

  /// Gets whether this trigger has fired.
  bool get hasTriggered => data[3] != 0;

  /// Sets whether this trigger has fired.
  set hasTriggered(bool value) => data[3] = value ? 1 : 0;
}
