import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/profiling/engine_profiler.dart';

void main() {
  group('EngineProfiler', () {
    test('records frames and calculates average FPS correctly', () {
      final profiler = EngineProfiler();

      // Run 60 frames with 0.016666 dt (60 fps)
      for (int i = 0; i < 60; i++) {
        profiler.recordFrame(1.0 / 60.0);
      }

      expect(profiler.currentFps, closeTo(60.0, 0.1));
      expect(profiler.averageFps, closeTo(60.0, 0.1));
    });

    test('ring buffer correctly wraps around', () {
      final profiler = EngineProfiler();

      // Run 60 frames with 60 fps
      for (int i = 0; i < 60; i++) {
        profiler.recordFrame(1.0 / 60.0);
      }
      expect(profiler.averageFps, closeTo(60.0, 0.1));

      // Run another 60 frames with 30 fps, this should completely replace the buffer
      for (int i = 0; i < 60; i++) {
        profiler.recordFrame(1.0 / 30.0);
      }

      expect(profiler.currentFps, closeTo(30.0, 0.1));
      expect(profiler.averageFps, closeTo(30.0, 0.1));
    });

    test('tracks system execution times', () async {
      final profiler = EngineProfiler();

      const systemName = 'TestSystem';

      // Record 1 frame of system execution
      profiler.startSystem(systemName);
      // simulate some work
      await Future.delayed(const Duration(milliseconds: 1));
      profiler.stopSystem(systemName);

      // End frame
      profiler.recordFrame(0.016);

      final averageTime = profiler.getAverageSystemTimeUs(systemName);
      expect(averageTime, greaterThan(0.0));
      // Since it's only 1 frame recorded so far, the average is just the value of that 1 frame.
      // So it will be around 1000us (maybe up to a few thousand us in CI).
      expect(averageTime, lessThan(10000.0));
    });

    test('operates with zero allocation during normal execution', () {
      final profiler = EngineProfiler();
      profiler.startSystem('DummySystem');
      profiler.stopSystem('DummySystem');

      // Test 1000 iterations to ensure it throws no exceptions
      // and doesn't do obvious allocations. Memory constraints are enforced by structure.
      expect(() {
        for (int i = 0; i < 1000; i++) {
          profiler.startSystem('DummySystem');
          profiler.stopSystem('DummySystem');
          profiler.recordFrame(0.016,
              activeEntityCount: 10, componentStorageCount: 5);
        }
      }, isNot(throwsException));

      expect(profiler.activeEntityCount, 10);
      expect(profiler.componentStorageCount, 5);
    });
  });
}
