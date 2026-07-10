import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/world_ui.dart';

void main() {
  test('WorldUI sets and gets properties correctly via flat Float32List', () {
    final worldUi = WorldUI.create(42.0, 5.0, 10.0);

    expect(worldUi.targetUiEntityId, 42.0);
    expect(worldUi.offsetX, 5.0);
    expect(worldUi.offsetY, 10.0);

    worldUi.targetUiEntityId = 99.0;
    worldUi.offsetX = -15.0;
    worldUi.offsetY = 20.0;

    expect(worldUi.targetUiEntityId, 99.0);
    expect(worldUi.offsetX, -15.0);
    expect(worldUi.offsetY, 20.0);
  });
}
