import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/shader_material.dart';

void main() {
  test('ShaderMaterial initializes uniforms correctly', () {
    // We cannot instantiate FragmentShader directly, so we pass null and cast it
    // just to test the component array logic, bypassing the type check for this unit test.
    final material = ShaderMaterial(null, 3);

    expect(material.uniforms.length, 3);
    expect(material.uniforms, isA<Float32List>());

    // Verify it doesn't throw when updating
    material.uniforms[0] = 1.0;
    material.uniforms[1] = 2.0;
    material.uniforms[2] = 3.0;

    expect(material.uniforms[0], 1.0);
    expect(material.uniforms[1], 2.0);
    expect(material.uniforms[2], 3.0);
  });
}
