import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/ecs/component_caste.dart';
import 'package:sting/engine/components/position.dart';
import 'package:sting/engine/components/viewport.dart';
import 'package:sting/engine/components/world_ui.dart';
import 'package:sting/engine/components/complex_ui.dart';
import 'package:sting/engine/systems/world_ui_system.dart';

void main() {
  test('WorldUISystem updates target UI position relative to viewport', () {
    final positionCaste = ComponentCaste<Position>(10);
    final worldUiCaste = ComponentCaste<WorldUI>(10);
    final complexUiCaste = ComponentCaste<ComplexUI>(10);

    final system = WorldUISystem(
      positionCaste: positionCaste,
      worldUiCaste: worldUiCaste,
      complexUiCaste: complexUiCaste,
    );

    // Entity 1 is a game entity in the world
    positionCaste.add(1, Position.create(100.0, 200.0));

    // Entity 2 is a UI entity
    final complexUi = ComplexUI(x: 0, y: 0, width: 50, height: 10);
    complexUiCaste.add(2, complexUi);

    // Connect Entity 1 to Entity 2 with an offset
    worldUiCaste.add(1, WorldUI.create(2.0, -10.0, -20.0));

    final viewport = Viewport.create(50.0, 50.0, 2.0);

    system.update(viewport);

    // Screen X = (100 - 50) * 2 - 10 = 50 * 2 - 10 = 90
    // Screen Y = (200 - 50) * 2 - 20 = 150 * 2 - 20 = 280
    expect(complexUi.x, 90.0);
    expect(complexUi.y, 280.0);
  });
}
