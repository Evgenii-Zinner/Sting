#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / u_resolution;
    fragColor = vec4(st.x, st.y, 0.0, 1.0);
}
