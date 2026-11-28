import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme dùng chung cho cả 5 thư mục features.
/// Mọi màn hình chỉ sử dụng AppTheme / AppColors để đảm bảo đồng bộ 100%.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          letterSpacing: -0.2,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariantSoft,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: AppColors.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: AppColors.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: AppColors.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Style số tiền tabular-nums (tương đương font-mono tabular-nums trong Stitch)
  static TextStyle monoAmount({
    double fontSize = 15,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.onSurface,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
