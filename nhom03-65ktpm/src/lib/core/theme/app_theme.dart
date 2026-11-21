import 'package:flutter/material.dart';

/// Theme dùng chung cho toàn app (Material 3, hỗ trợ sáng/tối).
abstract final class AppTheme {
  static const Color _seedColor = Color(0xFF2F6BFF);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
    );
  }
}
