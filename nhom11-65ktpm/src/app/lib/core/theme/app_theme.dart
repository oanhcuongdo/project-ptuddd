import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'glass_theme.dart';

/// Theme chủ đạo: vật liệu Liquid Glass (iOS 26) cho bề mặt nổi
/// + hình khối, chữ đậm và chuyển động của Material 3 Expressive.
class AppTheme {
  static const _fontFallback = ['Noto Sans SC', 'Roboto', 'PingFang SC'];

  /// Tiêu đề dùng chữ có chân (serif) mềm mại kiểu biên tập – đặc trưng
  /// của phong cách Anthropic; thân chữ vẫn là sans để dễ đọc.
  static const _serif = 'serif';
  static const _serifFallback = ['Noto Serif', 'Noto Serif SC', 'Georgia', 'Times New Roman', 'serif'];

  /// Bo góc chuẩn (squircle liên tục kiểu iOS).
  static const double radiusSmall = 14;
  static const double radiusMedium = 22;
  static const double radiusLarge = 30;

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final glass = isDark ? GlassTheme.dark : GlassTheme.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: isDark ? AppColors.primaryLight : AppColors.primary,
      // Chữ trên nền clay: trắng ở light (clay đậm), than chì ở dark (clay sáng) – đủ tương phản.
      onPrimary: isDark ? AppColors.slate : Colors.white,
      secondary: isDark ? AppColors.secondaryLight : AppColors.secondary,
      error: AppColors.errorRed,
      tertiary: AppColors.olive,
      surface: isDark ? AppColors.backgroundDark : AppColors.ivory,
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      onSurfaceVariant: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      outline: isDark ? const Color(0xFF6B6A64) : AppColors.cloud,
      outlineVariant: isDark ? AppColors.dividerDark : AppColors.dividerLight,
      surfaceContainerHighest: isDark ? AppColors.slateLight : AppColors.pampas,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamilyFallback: _fontFallback,
    );

    // Chữ kiểu Expressive: tiêu đề rất đậm, tracking âm nhẹ như SF Pro Display.
    TextStyle? serif(TextStyle? s, FontWeight w, double tracking) =>
        s?.copyWith(fontFamily: _serif, fontFamilyFallback: _serifFallback, fontWeight: w, letterSpacing: tracking);
    final text = base.textTheme.copyWith(
      displaySmall: serif(base.textTheme.displaySmall, FontWeight.w600, -0.8),
      headlineLarge: serif(base.textTheme.headlineLarge, FontWeight.w600, -0.6),
      headlineMedium: serif(base.textTheme.headlineMedium, FontWeight.w600, -0.4),
      headlineSmall: serif(base.textTheme.headlineSmall, FontWeight.w600, -0.3),
      titleLarge: serif(base.textTheme.titleLarge, FontWeight.w600, -0.2),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    const pill = StadiumBorder();
    final buttonPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
    final buttonText = const TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: glass.backdropBase,
      extensions: [glass],
      splashFactory: NoSplash.splashFactory, // iOS không có gợn sóng; phản hồi bằng lò xo
      highlightColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleMedium?.copyWith(color: scheme.onSurface, fontSize: 17),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: glass.tint,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          side: BorderSide(color: glass.rimHighlight.withValues(alpha: 0.5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: buttonPadding,
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: buttonPadding,
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: buttonPadding,
          shape: pill,
          textStyle: buttonText,
          backgroundColor: glass.tint,
          side: BorderSide(color: glass.rimHighlight),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: pill, textStyle: buttonText),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        backgroundColor: glass.tint,
        side: BorderSide(color: glass.rimHighlight.withValues(alpha: 0.6)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glass.tint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: glass.rimHighlight.withValues(alpha: 0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: glass.rimHighlight.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: glass.thickTint.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radiusLarge)),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBackgroundColor: Colors.transparent,
        modalElevation: 0,
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: const Size(40, 5),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xF23D3D3A) : const Color(0xF2141413),
        contentTextStyle: const TextStyle(color: AppColors.ivory, fontWeight: FontWeight.w500),
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primary.withValues(alpha: 0.12),
        circularTrackColor: scheme.primary.withValues(alpha: 0.12),
        strokeCap: StrokeCap.round,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: ShapeDecoration(
          color: isDark ? const Color(0xF23D3D3A) : const Color(0xF2141413),
          shape: const StadiumBorder(),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5), space: 1),
      iconTheme: IconThemeData(color: scheme.onSurface),
      cupertinoOverrideTheme: CupertinoThemeData(primaryColor: scheme.primary, brightness: brightness),
    );
  }
}
