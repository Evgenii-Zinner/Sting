import 'dart:typed_data';

/// A zero-allocation ring buffer for dispatching audio events.
///
/// Follows Data-Oriented Design (DOD) principles by storing events in a flat `Int32List`.
/// Avoids instantiating `SoundEvent` objects per frame.
class AudioEventQueue {
  /// The maximum number of events the queue can hold.
  final int capacity;

  /// The size in ints of a single event in the queue.
  /// 5 ints per event: sound ID, entity ID, volume (fixed-point), pitch (fixed-point), loop (0/1).
  static const int eventSize = 5;

  final Int32List _data;
  int _head = 0;
  int _tail = 0;
  int _count = 0;

  /// Creates a new [AudioEventQueue] with the given [capacity].
  AudioEventQueue(this.capacity) : _data = Int32List(capacity * eventSize);

  /// The number of events currently in the queue.
  int get length => _count;

  /// Adds a new audio event to the queue.
  ///
  /// Returns `true` if the event was successfully added, or `false` if the queue is full.
  bool enqueue(
    int soundId,
    int entityId, {
    double volume = 1.0,
    double pitch = 1.0,
    bool loop = false,
  }) {
    if (_count >= capacity) {
      return false;
    }

    final int index = _tail * eventSize;
    _data[index] = soundId;
    _data[index + 1] = entityId;
    _data[index + 2] = (volume * 1000).toInt();
    _data[index + 3] = (pitch * 1000).toInt();
    _data[index + 4] = loop ? 1 : 0;

    _tail = (_tail + 1) % capacity;
    _count++;

    return true;
  }

  /// Processes all events currently in the queue using the provided callback.
  ///
  /// The callback is invoked with the primitive data for each event.
  /// Clears the queue after processing.
  void process(
    void Function(
      int soundId,
      int entityId,
      double volume,
      double pitch,
      bool loop,
    )
        callback,
  ) {
    int current = _head;
    int remaining = _count;

    while (remaining > 0) {
      final int index = current * eventSize;
      final int soundId = _data[index];
      final int entityId = _data[index + 1];
      final double volume = _data[index + 2] / 1000.0;
      final double pitch = _data[index + 3] / 1000.0;
      final bool loop = _data[index + 4] == 1;

      callback(soundId, entityId, volume, pitch, loop);

      current = (current + 1) % capacity;
      remaining--;
    }

    _head = 0;
    _tail = 0;
    _count = 0;
  }
}
