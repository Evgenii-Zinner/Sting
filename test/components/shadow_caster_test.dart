import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/shadow_caster.dart';

void main() {
  group('ShadowCaster Component', () {
    test('should initialize correctly via create', () {
      final caster = ShadowCaster.create();
      expect(caster.active, true);
      expect(caster.length, ShadowCaster.componentSize);

      final caster2 = ShadowCaster.create(active: false);
      expect(caster2.active, false);
    });

    test('should update properties correctly', () {
      final caster = ShadowCaster.create();
      expect(caster.active, true);

      caster.active = false;
      expect(caster.active, false);

      caster.active = true;
      expect(caster.active, true);
    });
  });
}
