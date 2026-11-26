import 'dart:math';
import 'dart:ui' show Offset;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_implementation.dart';
import 'models/hanzi.dart';

/// Dữ liệu nét chữ Hán. Chủ sở hữu: **Đệ** (#26 vẽ, #27 kiểm tra nét).
///
/// Bản thật gợi ý: đóng gói phần `graphics.txt` của Make Me a Hanzi cho các chữ
/// trong HSK 1–2 vào assets (hoặc lấy từ bảng `characters` trên server).
abstract class HanziRepository {
  /// Null nếu không có dữ liệu cho chữ này.
  Future<HanziStrokes?> strokes(String hanzi);

  /// Các chữ đang có dữ liệu (để màn luyện viết chọn).
  Future<List<String>> available();
}

final hanziRepositoryProvider = Provider<HanziRepository>((ref) => FakeHanziRepository());

/// Bản giả: 7 chữ đơn giản (一 二 三 十 人 大 口) với nét vẽ tay, cùng hệ toạ độ
/// Make Me a Hanzi. Nét là dải rộng ~70 đơn vị quanh đường trung tâm.
class FakeHanziRepository with FakeImplementation implements HanziRepository {
  static const Map<String, List<List<List<int>>>> _medians = {
    '一': [
      [[150, 390], [880, 400]],
    ],
    '二': [
      [[260, 620], [760, 630]],
      [[130, 180], [900, 190]],
    ],
    '三': [
      [[240, 700], [770, 710]],
      [[290, 420], [720, 430]],
      [[130, 120], [900, 130]],
    ],
    '十': [
      [[120, 400], [900, 410]],
      [[510, 800], [510, -60]],
    ],
    '人': [
      [[520, 800], [470, 500], [330, 200], [130, 0]],
      [[500, 420], [650, 200], [900, 0]],
    ],
    '大': [
      [[150, 500], [870, 510]],
      [[510, 820], [480, 450], [300, 120], [110, -40]],
      [[520, 420], [680, 170], [910, -20]],
    ],
    '口': [
      [[230, 640], [260, 40]],
      [[250, 640], [760, 660], [730, 40]],
      [[260, 90], [720, 90]],
    ],
  };

  @override
  Future<List<String>> available() async => _medians.keys.toList();

  @override
  Future<HanziStrokes?> strokes(String hanzi) async {
    final m = _medians[hanzi];
    if (m == null) return null;
    final medians = [
      for (final stroke in m) [for (final p in stroke) Offset(p[0].toDouble(), p[1].toDouble())],
    ];
    return HanziStrokes(hanzi: hanzi, strokes: [for (final s in medians) _outline(s, 35)], medians: medians);
  }

  /// Dựng SVG path kín bao quanh đường trung tâm (lệch hai bên một khoảng [w]).
  static String _outline(List<Offset> pts, double w) {
    Offset normal(Offset a, Offset b) {
      final d = b - a;
      final len = max(d.distance, 1e-6);
      return Offset(-d.dy / len, d.dx / len) * w;
    }

    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < pts.length; i++) {
      final n = normal(pts[max(0, i - 1)], pts[min(pts.length - 1, i + 1)]);
      left.add(pts[i] + n);
      right.add(pts[i] - n);
    }
    final poly = [...left, ...right.reversed];
    String f(double v) => v.toStringAsFixed(0);
    return 'M ${f(poly.first.dx)} ${f(poly.first.dy)} '
        '${[for (final p in poly.skip(1)) 'L ${f(p.dx)} ${f(p.dy)}'].join(' ')} Z';
  }
}
