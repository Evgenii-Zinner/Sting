import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sting/engine/components/normal_map_material.dart';
import 'package:sting/engine/components/shader_material.dart';

void main() {
  group('NormalMapMaterial Component', () {
    test('create() initializes with expected default values', () {
      final material = NormalMapMaterial.create(
        rectLeft: 0.0,
        rectTop: 10.0,
        rectRight: 100.0,
        rectBottom: 110.0,
      );

      expect(material.length, 7);
      expect(material, isA<Float32List>());

      expect(material.rectLeft, 0.0);
      expect(material.rectTop, 10.0);
      expect(material.rectRight, 100.0);
      expect(material.rectBottom, 110.0);
      expect(material.bumpDepth, 1.0);
      expect(material.specularPower, 16.0);
      expect(material.specularIntensity, closeTo(0.5, 0.0001));
    });

    test('create() accepts custom values', () {
      final material = NormalMapMaterial.create(
        rectLeft: 5.0,
        rectTop: 15.0,
        rectRight: 25.0,
        rectBottom: 35.0,
        bumpDepth: 2.0,
        specularPower: 32.0,
        specularIntensity: 0.8,
      );

      expect(material.rectLeft, 5.0);
      expect(material.rectTop, 15.0);
      expect(material.rectRight, 25.0);
      expect(material.rectBottom, 35.0);
      expect(material.bumpDepth, 2.0);
      expect(material.specularPower, 32.0);
      expect(material.specularIntensity, closeTo(0.8, 0.0001));
    });

    test('getters and setters work correctly', () {
      final material = NormalMapMaterial.create(
        rectLeft: 0.0,
        rectTop: 0.0,
        rectRight: 0.0,
        rectBottom: 0.0,
      );

      material.rectLeft = 10.0;
      material.rectTop = 20.0;
      material.rectRight = 30.0;
      material.rectBottom = 40.0;
      material.bumpDepth = 3.0;
      material.specularPower = 64.0;
      material.specularIntensity = 0.9;

      expect(material.rectLeft, 10.0);
      expect(material.rectTop, 20.0);
      expect(material.rectRight, 30.0);
      expect(material.rectBottom, 40.0);
      expect(material.bumpDepth, 3.0);
      expect(material.specularPower, 64.0);
      expect(material.specularIntensity, closeTo(0.9, 0.0001));
    });

    test('serializeUniforms copies values into ShaderMaterial correctly', () {
      final material = NormalMapMaterial.create(
        rectLeft: 1.0,
        rectTop: 2.0,
        rectRight: 3.0,
        rectBottom: 4.0,
        bumpDepth: 5.0,
        specularPower: 6.0,
        specularIntensity: 7.0,
      );

      final shaderMaterial = ShaderMaterial(null, 10);

      // Start writing from offset 2
      material.serializeUniforms(shaderMaterial, 2);

      expect(shaderMaterial.uniforms[0], 0.0);
      expect(shaderMaterial.uniforms[1], 0.0);
      expect(shaderMaterial.uniforms[2], 1.0);
      expect(shaderMaterial.uniforms[3], 2.0);
      expect(shaderMaterial.uniforms[4], 3.0);
      expect(shaderMaterial.uniforms[5], 4.0);
      expect(shaderMaterial.uniforms[6], 5.0);
      expect(shaderMaterial.uniforms[7], 6.0);
      expect(shaderMaterial.uniforms[8], 7.0);
      expect(shaderMaterial.uniforms[9], 0.0);
    });

    test('serializeUniforms throws RangeError if offset is invalid', () {
      final material = NormalMapMaterial.create(
        rectLeft: 1.0,
        rectTop: 2.0,
        rectRight: 3.0,
        rectBottom: 4.0,
      );

      final shaderMaterial = ShaderMaterial(null, 5); // Too small

      expect(() => material.serializeUniforms(shaderMaterial, 0), throwsRangeError);
      expect(() => material.serializeUniforms(shaderMaterial, -1), throwsRangeError);
    });
  });
}
