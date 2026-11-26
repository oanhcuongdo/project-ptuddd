import 'dart:ui' show Offset;

/// Dữ liệu nét của một chữ Hán, cùng định dạng với `graphics.txt` của
/// Make Me a Hanzi (https://github.com/skishore/makemeahanzi):
///
/// - Hệ toạ độ 1024 × 1024, trục y hướng LÊN, gốc dịch xuống 900:
///   đổi sang toạ độ màn hình bằng `Offset(x, 900 - y)` rồi scale theo ô vẽ.
/// - [strokes]: SVG path của từng nét (vẽ nét đầy đủ), theo đúng thứ tự viết.
/// - [medians]: đường trung tâm của từng nét (dùng kiểm tra hướng / thứ tự nét ở #27).
class HanziStrokes {
  final String hanzi;
  final List<String> strokes;
  final List<List<Offset>> medians;

  const HanziStrokes({required this.hanzi, required this.strokes, required this.medians});

  int get strokeCount => medians.length;

  factory HanziStrokes.fromJson(Map<String, dynamic> j) => HanziStrokes(
    hanzi: j['character'] as String,
    strokes: [for (final s in (j['strokes'] as List)) s as String],
    medians: [
      for (final m in (j['medians'] as List))
        [for (final p in (m as List)) Offset(((p as List)[0] as num).toDouble(), (p[1] as num).toDouble())],
    ],
  );

  Map<String, dynamic> toJson() => {
    'character': hanzi,
    'strokes': strokes,
    'medians': [
      for (final m in medians) [for (final p in m) [p.dx, p.dy]],
    ],
  };
}
