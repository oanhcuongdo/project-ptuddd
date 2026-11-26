#version 460 core
// Liquid Glass: khúc xạ nền ở mép kính (bezel), tán sắc nhẹ và ánh phản chiếu.
#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;       // kích thước texture nền (engine tự gán)
uniform vec4 u_rect;       // left, top, width, height của kính (pixel thiết bị)
uniform float u_radius;    // bán kính bo góc (pixel)
uniform float u_bezel;     // độ dày mép khúc xạ (pixel)
uniform float u_strength;  // độ lệch tối đa (pixel); > 0 lấy mẫu ra ngoài, < 0 vào trong
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
  // Chừa 2px: cột/hàng pixel sát mép texture nền có thể chứa rác.
  vec2 uv = clamp(px, vec2(2.0), u_size - 2.0) / u_size;
  return texture(u_texture, uv);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 half_size = u_rect.zw * 0.5;
  vec2 p = frag - (u_rect.xy + half_size);
  float r = min(u_radius, min(half_size.x, half_size.y));
  float d = sdRoundBox(p, half_size, r);

  // Pháp tuyến lấy từ một hình bo tròn hơn (bán kính ≥ bezel): với bán kính
  // thật, pháp tuyến bị gãy theo đường chéo trong dải bezel ở góc làm mẫu nền
  // nhảy cóc. Khoảng cách d vẫn dùng bán kính thật để khớp đúng hình cắt.
  float rn = min(max(r, u_bezel + 2.0), min(half_size.x, half_size.y));
  float e = 1.0;
  vec2 grad = vec2(
    sdRoundBox(p + vec2(e, 0.0), half_size, rn) - sdRoundBox(p - vec2(e, 0.0), half_size, rn),
    sdRoundBox(p + vec2(0.0, e), half_size, rn) - sdRoundBox(p - vec2(0.0, e), half_size, rn));
  vec2 n = length(grad) > 0.0 ? normalize(grad) : vec2(0.0);

  // 1 ở sát mép, giảm mượt (Gauss) về 0 vào trong lòng kính – không có
  // điểm gãy nên dải khúc xạ chuyển tiếp êm vào phần kính phẳng. Đuôi Gauss
  // kéo dài quá bezel (~1.6×) để ranh giới mép/lòng kính tan dần, không lộ.
  float x = max(-d, 0.0) / max(u_bezel, 1.0);
  float profile = exp(-1.8 * x * x);
  vec2 offset;
  if (u_strength >= 0.0) {
    // Kính trong: mép cong như thấu kính dày – lấy mẫu nền ở PHÍA NGOÀI rồi
    // nén vào dải bezel, nên nền xung quanh (cả bóng đổ) "tràn" vào mép kính.
    // Ánh xạ này luôn đơn điệu nên không bị gập dù độ lệch lớn.
    // (Chỉ dùng khi KHÔNG làm mờ trước: kết quả làm mờ chỉ có trong khung
    // kính, lấy mẫu ra ngoài sẽ thấy đường nối.)
    offset = n * profile * min(u_strength, 1.2 * u_bezel);
    // Lòng kính phóng to rất nhẹ (như mặt kính hơi vồng lên).
    offset -= p * 0.035 * (1.0 - profile);
  } else {
    // Kính mờ (dày): kéo mẫu vào trong. Giới hạn độ lệch để ánh xạ đơn điệu:
    // max|f'| của exp(-1.8x²) ≈ 1.15 → S < 0.87 · bezel.
    offset = n * profile * max(u_strength, -0.7 * u_bezel);
  }
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

  // Nền lấy từ phía ngoài mép có lẫn bóng đổ của chính kính nên tối hơn lòng
  // kính → thành một dải tối tách mép khỏi lòng kính. Giữ màu khúc xạ nhưng
  // kéo độ sáng về bằng nền ngay phía dưới (chỉ làm sáng, không làm tối).
  if (u_strength > 0.0) {
    const vec3 W = vec3(0.2126, 0.7152, 0.0722);
    float lr = dot(sampleAt(frag).rgb, W);
    float lc = dot(col.rgb, W);
    float gain = clamp(lr / max(lc, 1e-3), 1.0, 1.2);
    col.rgb = min(col.rgb * mix(1.0, gain, profile), vec3(col.a));
  }

  // Ánh phản chiếu: viền mảnh sáng theo hướng nguồn sáng (cả phía đối diện, yếu hơn).
  vec2 L = normalize(u_light.xy);
  float facing = dot(n, L);
  float rim = exp(-max(-d, 0.0) / max(u_light.w, 0.5));
  float spec = (pow(max(facing, 0.0), 2.0) + 0.45 * pow(max(-facing, 0.0), 2.0)) * rim * u_light.z;
  col.rgb = min(col.rgb + vec3(spec) * col.a, vec3(col.a));
  frag_color = col;
}
