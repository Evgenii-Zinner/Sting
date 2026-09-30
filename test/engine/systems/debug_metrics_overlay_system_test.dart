import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/profiling/engine_profiler.dart';
import 'package:sting/engine/ecs/scene.dart';
import 'package:sting/engine/systems/debug_metrics_overlay_system.dart';

void main() {
  group('DebugMetricsOverlaySystem', () {
    test('renders overlay without exceptions under and over dirty timer', () {
      final profiler = EngineProfiler();
      final scene = Scene();

      // Simulate some profiler data
      profiler.startSystem('SystemA');
      profiler.stopSystem('SystemA');
      profiler.recordFrame(0.016, activeEntityCount: 42, componentStorageCount: 5);

      final system = DebugMetricsOverlaySystem(
        profiler: profiler,
        scene: scene,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Should not throw
      expect(() {
        // Frame 1: under dirty timer
        system.update(0.016, canvas);

        // Frame 2: under dirty timer
        system.update(0.016, canvas);

        // Frame 3: push over dirty timer (0.25s) to trigger _updateParagraphs
        system.update(0.3, canvas);
      }, isNot(throwsException));

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('caps fallback in case of large dt', () {
      final profiler = EngineProfiler();
      final scene = Scene();

      final system = DebugMetricsOverlaySystem(
        profiler: profiler,
        scene: scene,
      );

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      expect(() {
        // Massive dt
        system.update(10.0, canvas);
      }, isNot(throwsException));
    });
  });
}
