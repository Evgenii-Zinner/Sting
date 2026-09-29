import 'dart:typed_data';

import 'package:sting/engine/components/shader_material.dart';

/// A Data-Oriented 2D Normal Map Material component.
///
/// Stored in a flat Float32List (7 elements):
/// - index 0: normalMapRectLeft
/// - index 1: normalMapRectTop
/// - index 2: normalMapRectRight
/// - index 3: normalMapRectBottom
/// - index 4: bumpDepth
/// - index 5: specularPower
/// - index 6: specularIntensity
extension type NormalMapMaterial(Float32List _data) implements Float32List {
  static const int componentSize = 7;

  NormalMapMaterial.create({
    required double rectLeft,
    required double rectTop,
    required double rectRight,
    required double rectBottom,
    double bumpDepth = 1.0,
    double specularPower = 16.0,
    double specularIntensity = 0.5,
  }) : _data = Float32List(componentSize) {
    this.rectLeft = rectLeft;
    this.rectTop = rectTop;
    this.rectRight = rectRight;
    this.rectBottom = rectBottom;
    this.bumpDepth = bumpDepth;
    this.specularPower = specularPower;
    this.specularIntensity = specularIntensity;
  }

  double get rectLeft => _data[0];
  set rectLeft(double value) => _data[0] = value;

  double get rectTop => _data[1];
  set rectTop(double value) => _data[1] = value;

  double get rectRight => _data[2];
  set rectRight(double value) => _data[2] = value;

  double get rectBottom => _data[3];
  set rectBottom(double value) => _data[3] = value;

  double get bumpDepth => _data[4];
  set bumpDepth(double value) => _data[4] = value;

  double get specularPower => _data[5];
  set specularPower(double value) => _data[5] = value;

  double get specularIntensity => _data[6];
  set specularIntensity(double value) => _data[6] = value;

  /// Serializes the properties into the given ShaderMaterial uniform array
  /// starting at the specified offset. Zero allocations.
  void serializeUniforms(ShaderMaterial material, int offset) {
    if (offset < 0 || offset + componentSize > material.uniforms.length) {
      throw RangeError('Offset out of bounds for ShaderMaterial uniforms');
    }
    for (int i = 0; i < componentSize; i++) {
      material.uniforms[offset + i] = _data[i];
    }
  }
}
