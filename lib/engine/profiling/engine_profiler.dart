import 'dart:typed_data';

/// A zero-allocation profiler for tracking engine performance metrics.
class EngineProfiler {
  int _frameIndex = 0;
  int _framesRecorded = 0;
  final Float32List _dtHistory = Float32List(60);
  final Map<String, Int64List> _systemTimesUs = {};
  final Map<String, Stopwatch> _stopwatches = {};
  double _currentFps = 0.0;
  double _averageFps = 0.0;
  int _activeEntityCount = 0;
  int _componentStorageCount = 0;

  double get currentFps => _currentFps;
  double get averageFps => _averageFps;
  int get activeEntityCount => _activeEntityCount;
  int get componentStorageCount => _componentStorageCount;
  Iterable<String> get trackedSystems => _systemTimesUs.keys;

  /// Starts timing for the specified system.
  void startSystem(String name) {
    var stopwatch = _stopwatches[name];
    if (stopwatch == null) {
      stopwatch = Stopwatch();
      _stopwatches[name] = stopwatch;
      _systemTimesUs[name] = Int64List(60);
    }
    stopwatch.reset();
    stopwatch.start();
  }

  /// Stops timing for the specified system and records elapsed time in the ring buffer.
  void stopSystem(String name) {
    final stopwatch = _stopwatches[name];
    if (stopwatch != null) {
      stopwatch.stop();
      final times = _systemTimesUs[name];
      if (times != null) {
        times[_frameIndex] = stopwatch.elapsedMicroseconds;
      }
    }
  }

  /// Records the end of a frame, updating frame tracking metrics.
  void recordFrame(double dt, {int activeEntityCount = 0, int componentStorageCount = 0}) {
    _dtHistory[_frameIndex] = dt;
    _activeEntityCount = activeEntityCount;
    _componentStorageCount = componentStorageCount;

    _currentFps = dt > 0.0 ? 1.0 / dt : 0.0;

    _framesRecorded++;
    final int count = _framesRecorded < 60 ? _framesRecorded : 60;

    double totalDt = 0.0;
    for (int i = 0; i < count; i++) {
      totalDt += _dtHistory[i];
    }
    _averageFps = totalDt > 0.0 ? count / totalDt : 0.0;

    _frameIndex = (_frameIndex + 1) % 60;
  }

  /// Gets the average execution time in microseconds for the specified system
  /// over the last 60 frames.
  double getAverageSystemTimeUs(String name) {
    final times = _systemTimesUs[name];
    if (times == null) return 0.0;

    final int count = _framesRecorded < 60 ? _framesRecorded : 60;
    if (count == 0) return 0.0;

    double totalTime = 0.0;
    for (int i = 0; i < count; i++) {
      totalTime += times[i];
    }
    return totalTime / count;
  }
}
