#version 460 core
// Liquid Glass: khúc xạ nền ở mép kính (bezel), tán sắc nhẹ và ánh phản chiếu.
#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;       // kích thước texture nền (engine tự gán)
uniform vec4 u_rect;       // left, top, width, height của kính (pixel thiết bị)
uniform float u_radius;    // bán kính bo góc (pixel)
uniform float u_bezel;     // độ dày mép khúc xạ (pixel)
uniform float u_strength;  // độ lệch tối đa khi khúc xạ (pixel)
uniform float u_dispersion;// tán sắc (0..1)
uniform vec4 u_light;      // xy = hướng sáng, z = độ sáng viền, w = độ dày viền (pixel)
uniform sampler2D u_texture;

out vec4 frag_color;

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec4 sampleAt(vec2 px) {
  // Không lật trục y ở GLES: với BackdropFilter, FlutterFragCoord và texture
  // nền đã cùng hướng (đã kiểm tra trên máy thật Impeller/OpenGLES).
  vec2 uv = clamp(px / u_size, vec2(0.0), vec2(1.0));
  return texture(u_texture, uv);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 half_size = u_rect.zw * 0.5;
  vec2 p = frag - (u_rect.xy + half_size);
  float r = min(u_radius, min(half_size.x, half_size.y));
  float d = sdRoundBox(p, half_size, r);

  // Pháp tuyến mặt kính từ gradient của SDF.
  float e = 1.0;
  vec2 grad = vec2(
    sdRoundBox(p + vec2(e, 0.0), half_size, r) - sdRoundBox(p - vec2(e, 0.0), half_size, r),
    sdRoundBox(p + vec2(0.0, e), half_size, r) - sdRoundBox(p - vec2(0.0, e), half_size, r));
  vec2 n = length(grad) > 0.0 ? normalize(grad) : vec2(0.0);

  // 0 ở trong lòng kính, 1 ở sát mép. Mặt cong dạng vòm (circle profile).
  float inside = clamp(-d, 0.0, u_bezel);
  float t = 1.0 - inside / max(u_bezel, 1.0);
  float profile = t * t;

  // Kéo mẫu nền vào phía trong → nền bị bẻ cong ở mép. Giới hạn độ lệch để
  // ánh xạ luôn đơn điệu (không bị "gập" tạo vệt sáng): S * f'(t) / bezel < 1.
  float strength = min(u_strength, 0.45 * u_bezel);
  vec2 offset = -n * profile * strength;
  vec4 col;
  if (u_dispersion > 0.0) {
    float k = u_dispersion * profile;
    col.r = sampleAt(frag + offset * (1.0 - 0.10 * k)).r;
    col.g = sampleAt(frag + offset).g;
    col.b = sampleAt(frag + offset * (1.0 + 0.12 * k)).b;
    col.a = sampleAt(frag + offset).a;
  } else {
    col = sampleAt(frag + offset);
  }

  // Ánh phản chiếu: viền mảnh sáng theo hướng nguồn sáng (cả phía đối diện, yếu hơn).
  vec2 L = normalize(u_light.xy);
  float facing = dot(n, L);
  float rim = exp(-max(-d, 0.0) / max(u_light.w, 0.5));
  float spec = (pow(max(facing, 0.0), 2.0) + 0.45 * pow(max(-facing, 0.0), 2.0)) * rim * u_light.z;
  // Dải sáng mềm trên bezel làm kính có độ dày.
  spec += profile * profile * 0.18 * u_light.z * (0.5 + 0.5 * abs(facing));
  col.rgb = min(col.rgb + vec3(spec) * col.a, vec3(col.a));
  frag_color = col;
}
