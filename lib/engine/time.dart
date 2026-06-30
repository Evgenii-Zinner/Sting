class Time {
  /// The delta time of the current frame in seconds.
  double _dt = 0.0;
  double get dt => _dt;

  /// The fixed delta time step in seconds (e.g. 1/60 for 60Hz).
  final double fixedDeltaTime;

  /// Accumulator for fixed timestep game loop.
  double _accumulator = 0.0;

  /// The timestamp of the previous frame in microseconds.
  /// Initialized to -1 to indicate the first frame.
  int _lastTimeMicroseconds = -1;

  /// The maximum allowed delta time in seconds.
  /// This prevents huge time jumps on lag spikes (e.g. game paused in background).
  final double maxDt;

  Time({this.maxDt = 0.1, this.fixedDeltaTime = 1 / 60.0});

  /// Updates the delta time based on the new frame timestamp and adds to the accumulator.
  /// The timestamp is typically from [Duration.inMicroseconds].
  void update(int currentMicroseconds) {
    if (_lastTimeMicroseconds == -1) {
      // First frame, dt is 0
      _dt = 0.0;
    } else {
      int diffMicroseconds = currentMicroseconds - _lastTimeMicroseconds;

      // Prevent negative time if timestamps are out of order
      if (diffMicroseconds < 0) {
        diffMicroseconds = 0;
      }

      _dt = diffMicroseconds / 1000000.0; // convert microseconds to seconds

      // Cap at maxDt
      if (_dt > maxDt) {
        _dt = maxDt;
      }

      _accumulator += _dt;
    }

    _lastTimeMicroseconds = currentMicroseconds;
  }

  /// Consumes one fixed time step if enough time has accumulated.
  /// Returns true if a step was consumed, false otherwise.
  bool consumeFixedStep() {
    if (_accumulator >= fixedDeltaTime) {
      _accumulator -= fixedDeltaTime;
      return true;
    }
    return false;
  }
}
