import 'package:flutter/material.dart';

import '../../domain/enums.dart';

/// Màu cho chip mức độ: xanh lá / vàng / cam.
///
/// KHÔNG dùng màu đỏ để tránh cảm giác chê trách người dùng.
/// Với rau và đạm thì đảo màu (nhiều = xanh).
enum LevelTone { good, neutral, caution }

class LevelColors {
  LevelColors._();

  static LevelTone toneOf(LevelAttribute attribute, Level level) {
    final good = attribute.higherIsBetter ? Level.high : Level.low;
    final caution = attribute.higherIsBetter ? Level.low : Level.high;
    if (level == good) return LevelTone.good;
    if (level == caution) return LevelTone.caution;
    return LevelTone.neutral;
  }

  static ({Color background, Color foreground}) colorsOf(
    LevelTone tone,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    return switch (tone) {
      LevelTone.good => dark
          ? (background: const Color(0xFF14532D), foreground: const Color(0xFFBBF7D0))
          : (background: const Color(0xFFDCFCE7), foreground: const Color(0xFF166534)),
      LevelTone.neutral => dark
          ? (background: const Color(0xFF713F12), foreground: const Color(0xFFFEF08A))
          : (background: const Color(0xFFFEF9C3), foreground: const Color(0xFF854D0E)),
      LevelTone.caution => dark
          ? (background: const Color(0xFF7C2D12), foreground: const Color(0xFFFED7AA))
          : (background: const Color(0xFFFFEDD5), foreground: const Color(0xFF9A3412)),
    };
  }

  /// Màu viền cảnh báo "Vui lòng kiểm tra lại" (vàng).
  static const Color reviewBorder = Color(0xFFF59E0B);
}
