import 'dart:typed_data';
import 'dart:ui';

/// A component storing a shader program and a contiguous float buffer for uniforms.
class ShaderMaterial {
  /// The compiled shader program.
  final FragmentShader? shader;

  /// The flat buffer for float uniform parameters.
  final Float32List uniforms;

  ShaderMaterial(this.shader, int uniformCount)
      : uniforms = Float32List(uniformCount);
}
