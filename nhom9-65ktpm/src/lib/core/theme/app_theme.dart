import 'package:flutter/material.dart';

class AppTheme {
  // Bảng màu thương hiệu BuddyTalk.
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color streakOrange = Color(0xFFFF6D00);

  static const Color _lightSecondaryContainer = Color(0xFFC9F0EB);
  static const Color _lightOnSecondaryContainer = Color(0xFF00201D);
  static const Color _darkSecondaryContainer = Color(0xFF00504A);
  static const Color _darkOnSecondaryContainer = Color(0xFFA5F0E7);
  static const Color _lightTertiaryContainer = Color(0xFFFFE0B2);
  static const Color _lightOnTertiaryContainer = Color(0xFF2A1700);
  static const Color _darkTertiaryContainer = Color(0xFF5C3A00);
  static const Color _darkOnTertiaryContainer = Color(0xFFFFE0B2);

  static ThemeData get lightTheme {
    return _createTheme(Brightness.light);
  }

  static ThemeData get darkTheme {
    return _createTheme(Brightness.dark);
  }

  static ThemeData _createTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    ).copyWith(
      secondary: secondaryColor,
      onSecondary: const Color(0xFF00201D),
      secondaryContainer:
          isLight ? _lightSecondaryContainer : _darkSecondaryContainer,
      onSecondaryContainer:
          isLight ? _lightOnSecondaryContainer : _darkOnSecondaryContainer,
      tertiary: accentColor,
      onTertiary: const Color(0xFF2A1700),
      tertiaryContainer:
          isLight ? _lightTertiaryContainer : _darkTertiaryContainer,
      onTertiaryContainer:
          isLight ? _lightOnTertiaryContainer : _darkOnTertiaryContainer,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
      ),
    );
  }
}
