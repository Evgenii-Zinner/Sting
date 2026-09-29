import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/progress_bar.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/ecs/component_storage.dart';
import 'package:sting/engine/systems/progress_bar_render_system.dart';

void main() {
  group('ProgressBarRenderSystem', () {
    test('update smoothly moves visualValue towards currentValue', () {
      final progressBars = ComponentStorage<ProgressBar>(10);
      final system = ProgressBarRenderSystem(progressBars);

      final bar = ProgressBar.create(currentValue: 50.0, catchUpSpeed: 1.0);
      bar.visualValue = 100.0; // Simulated damage from 100 to 50

      progressBars.add(1, bar);

      // Simulate 1 second at speed 1.0 -> diff is 50 -> visualValue decreases by 50 * 1.0 * 0.1 = 5 per frame for 0.1s
      system.update(0.1);
      expect(bar.visualValue, closeTo(95.0, 0.0001));

      system.update(0.1);
      expect(bar.visualValue, closeTo(90.5, 0.0001)); // (50 - 95) * 0.1 = -4.5

      // Update enough to drop within 0.1 delta
      for (int i = 0; i < 100; i++) {
        system.update(0.1);
      }
      expect(bar.visualValue, closeTo(50.0, 0.0001));
    });

    test('render pass without allocating (screen space)', () {
      final progressBars = ComponentStorage<ProgressBar>(10);
      final system = ProgressBarRenderSystem(progressBars);

      final bar = ProgressBar.create(
        currentValue: 50.0,
        maxValue: 100.0,
        isWorldSpace: 0.0, // screen space
        offsetX: 10.0,
        offsetY: 20.0,
      );
      progressBars.add(1, bar);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Should run without throwing errors or exceptions
      expect(() => system.render(canvas), returnsNormally);
    });

    test('render pass without allocating (world space with position)', () {
      final progressBars = ComponentStorage<ProgressBar>(10);
      final positions = ComponentStorage<Position>(10);
      final viewports = ComponentStorage<Viewport>(10);
      final system = ProgressBarRenderSystem(
        progressBars,
        positions: positions,
        viewports: viewports,
      );

      final bar = ProgressBar.create(
        currentValue: 50.0,
        maxValue: 100.0,
        isWorldSpace: 1.0, // world space
        segments: 4.0, // trigger segmented rendering branch
        offsetX: 10.0,
        offsetY: 20.0,
      );
      progressBars.add(1, bar);

      final pos = Position.create(100.0, 100.0);
      positions.add(1, pos);

      final vp = Viewport.create(50.0, 50.0, 2.0);
      viewports.add(0, vp); // Typically entity 0 holds the viewport

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // Should run without throwing errors or exceptions
      expect(() => system.render(canvas), returnsNormally);
    });
  });
}
