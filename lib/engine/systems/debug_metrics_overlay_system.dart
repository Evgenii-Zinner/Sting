import 'dart:ui' as ui;

import 'package:sting/engine/profiling/engine_profiler.dart';
import 'package:sting/engine/ecs/scene.dart';

/// Optional render system that displays a clean diagnostics HUD overlay.
///
/// Uses cached [ui.Paragraph] objects updated only on a dirty timer
/// so regular render frames produce zero heap allocations.
class DebugMetricsOverlaySystem {
  final EngineProfiler profiler;
  final Scene scene;

  double _timeSinceLastUpdate = 0.0;
  final double updateInterval = 0.25;

  ui.Paragraph? _fpsParagraph;
  ui.Paragraph? _systemsParagraph;

  final ui.Paint _bgPaint = ui.Paint()..color = const ui.Color(0xAA000000);

  final ui.Rect _bgRect = const ui.Rect.fromLTWH(0, 0, 300.0, 400.0);

  DebugMetricsOverlaySystem({
    required this.profiler,
    required this.scene,
  }) {
    // Initial update to populate paragraphs
    _updateParagraphs();
  }

  /// Updates and renders the debug overlay.
  void update(double dt, ui.Canvas canvas) {
    _timeSinceLastUpdate += dt;
    if (_timeSinceLastUpdate >= updateInterval) {
      _timeSinceLastUpdate -= updateInterval;
      // Cap fallback in case of large dt
      if (_timeSinceLastUpdate >= updateInterval) {
        _timeSinceLastUpdate = 0.0;
      }
      _updateParagraphs();
    }

    // Draw background
    canvas.drawRect(_bgRect, _bgPaint);

    // Draw FPS paragraph
    final fpsP = _fpsParagraph;
    if (fpsP != null) {
      canvas.drawParagraph(fpsP, const ui.Offset(10, 10));
    }

    // Draw systems paragraph
    final sysP = _systemsParagraph;
    if (sysP != null) {
      canvas.drawParagraph(sysP, const ui.Offset(10, 60));
    }
  }

  void _updateParagraphs() {
    final double dtMs = _dtHistoryAverageMs();
    final String fpsText =
        'FPS: ${profiler.averageFps.toStringAsFixed(1)} (${dtMs.toStringAsFixed(2)} ms)\n'
        'Entities: ${profiler.activeEntityCount}\n'
        'Storages: ${profiler.componentStorageCount}';

    final fpsBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.left,
        fontSize: 14.0,
        maxLines: 3,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF00FF00)))
      ..addText(fpsText);

    _fpsParagraph = fpsBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 280.0));

    // Compile system times, sort descending, grab top 10
    final List<MapEntry<String, double>> systemEntries = profiler.trackedSystems
        .map((name) => MapEntry(name, profiler.getAverageSystemTimeUs(name)))
        .toList();

    systemEntries.sort((a, b) => b.value.compareTo(a.value));

    final int topCount = systemEntries.length > 15 ? 15 : systemEntries.length;

    final StringBuffer sysText = StringBuffer();
    sysText.writeln('Top Systems (Avg µs):');
    for (int i = 0; i < topCount; i++) {
      final entry = systemEntries[i];
      sysText.writeln('${entry.key}: ${entry.value.toStringAsFixed(0)}µs');
    }

    final sysBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.left,
        fontSize: 12.0,
        maxLines: topCount + 1,
      ),
    )
      ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFFFFFFF)))
      ..addText(sysText.toString());

    _systemsParagraph = sysBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 280.0));
  }

  double _dtHistoryAverageMs() {
    if (profiler.averageFps > 0.0) {
      return (1.0 / profiler.averageFps) * 1000.0;
    }
    return 0.0;
  }
}
