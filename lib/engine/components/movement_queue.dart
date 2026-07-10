import 'dart:typed_data';

/// A circular queue of waypoints for movement, backed by a flat Int32List.
/// Designed for zero-allocation pathfinding and navigation.
extension type MovementQueue(Int32List data) {
  static const int _metaSize = 4;
  static const int _idxHead = 0;
  static const int _idxTail = 1;
  static const int _idxCount = 2;
  static const int _idxCapacity = 3;

  /// Creates a new MovementQueue with the specified capacity.
  MovementQueue.create(int capacity)
      : this(Int32List(capacity + _metaSize)
          ..[_idxHead] = 0
          ..[_idxTail] = 0
          ..[_idxCount] = 0
          ..[_idxCapacity] = capacity);

  /// Gets the current head index.
  int get head => data[_idxHead];
  set head(int value) => data[_idxHead] = value;

  /// Gets the current tail index.
  int get tail => data[_idxTail];
  set tail(int value) => data[_idxTail] = value;

  /// Gets the current number of waypoints in the queue.
  int get count => data[_idxCount];
  set count(int value) => data[_idxCount] = value;

  /// Gets the maximum capacity of the queue.
  int get capacity => data[_idxCapacity];

  /// Returns true if the queue is empty.
  bool get isEmpty => count == 0;

  /// Returns true if the queue is full.
  bool get isFull => count >= capacity;

  /// Enqueues a new waypoint into the circular queue.
  /// Does nothing if the queue is full.
  void enqueue(int waypoint) {
    if (isFull) return;

    data[_metaSize + tail] = waypoint;
    tail = (tail + 1) % capacity;
    count++;
  }

  /// Dequeues and returns the next waypoint from the circular queue.
  /// Returns -1 if the queue is empty.
  int dequeue() {
    if (isEmpty) return -1;

    final waypoint = data[_metaSize + head];
    head = (head + 1) % capacity;
    count--;
    return waypoint;
  }

  /// Returns the next waypoint without removing it.
  /// Returns -1 if the queue is empty.
  int peek() {
    if (isEmpty) return -1;
    return data[_metaSize + head];
  }

  /// Clears all waypoints from the queue.
  void clear() {
    head = 0;
    tail = 0;
    count = 0;
  }
}
