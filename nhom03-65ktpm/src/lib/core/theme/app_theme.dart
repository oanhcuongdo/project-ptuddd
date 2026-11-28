import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Theme dùng chung cho toàn app (Material 3, hỗ trợ sáng/tối).
///
/// Token ở đây là nguồn sự thật duy nhất cho màu, typography, khoảng cách và
/// hình dạng — xem `docs/ui_ux.md`. Widget không được tự đặt màu/cỡ chữ.
///
/// Palette lấy từ bộ tham chiếu `docs/SmartNote_UI_Reference_Assets`:
/// `13_design_system.png` (Primary blue, Background xanh rất nhạt, Surface
/// trắng, Success/Warning/Error) và `02_notes_google_keep_inspired.png` (thẻ
/// pastel, chip lọc, bo góc lớn).
abstract final class AppTheme {
  /// Màu thương hiệu gốc — cũng là `primary` của bảng sáng.
  static const Color seed = Color(0xFF2F6BFF);

  static ThemeData get light => _build(_lightScheme, Brightness.light);

  static ThemeData get dark => _build(_darkScheme, Brightness.dark);

  /// Theme dành cho thư viện Ghi chú và thanh điều hướng của tab này.
  static ThemeData notes(ThemeData base) {
    final dark = base.brightness == Brightness.dark;
    final scheme = base.colorScheme.copyWith(
      primary: const Color(0xFF4721D5),
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: dark
          ? const Color(0xFF3B2A67)
          : const Color(0xFFE5DBFF),
      onPrimaryContainer: dark
          ? const Color(0xFFEDE4FF)
          : const Color(0xFF21154B),
      surface: dark ? const Color(0xFF171323) : const Color(0xFFFBF9FF),
      onSurface: dark ? const Color(0xFFF5EEFF) : const Color(0xFF21154B),
      onSurfaceVariant: dark
          ? const Color(0xFFC8BCDF)
          : const Color(0xFF63547E),
      surfaceContainerHigh: dark
          ? const Color(0xFF2A2140)
          : const Color(0xFFF0EAFF),
      outlineVariant: dark ? const Color(0xFF483663) : const Color(0xFFE4D9FF),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(NotesLayout.searchRadius),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    final typography = base.textTheme;
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: typography.copyWith(
        headlineLarge: typography.headlineLarge?.copyWith(
          fontSize: 47,
          fontWeight: FontWeight.w900,
          letterSpacing: -2.6,
          height: 1.12,
          color: scheme.onSurface,
        ),
        headlineSmall: typography.headlineSmall?.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          letterSpacing: -.55,
          height: 1.12,
          color: scheme.onSurface,
        ),
        titleMedium: typography.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
        titleSmall: typography.titleSmall?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: -.3,
          height: 1.12,
          color: scheme.onSurface,
        ),
        bodySmall: typography.bodySmall?.copyWith(
          fontSize: 11,
          height: 1.22,
          color: scheme.onSurfaceVariant,
        ),
        labelLarge: typography.labelLarge?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: dark ? scheme.onPrimaryContainer : scheme.primary,
          ),
        ),
        hintStyle: typography.bodyMedium?.copyWith(color: scheme.onSurface),
        prefixIconColor: scheme.onSurface,
        suffixIconColor: scheme.onSurface,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        height: NotesLayout.navigationHeight,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 20,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurface,
          ),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          typography.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2F6BFF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE3ECFF),
    onPrimaryContainer: Color(0xFF0B2B6B),
    secondary: Color(0xFF0E9F7E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDCF6EC),
    onSecondaryContainer: Color(0xFF075443),
    tertiary: Color(0xFF7C5CFF),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFEDE7FF),
    onTertiaryContainer: Color(0xFF2E1B6B),
    error: Color(0xFFD92D36),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFDE7E8),
    onErrorContainer: Color(0xFF7A1216),
    surface: Color(0xFFF5F8FF),
    onSurface: Color(0xFF101828),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHigh: Color(0xFFF0F3FB),
    surfaceContainerHighest: Color(0xFFE8EDF7),
    onSurfaceVariant: Color(0xFF5A667C),
    outline: Color(0xFF98A2B3),
    outlineVariant: Color(0xFFE3E9F4),
    shadow: Color(0xFF0B1220),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1D2939),
    onInverseSurface: Color(0xFFF2F4F7),
    inversePrimary: Color(0xFF9DBAFF),
    surfaceTint: Color(0xFF2F6BFF),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7FA5FF),
    onPrimary: Color(0xFF062045),
    primaryContainer: Color(0xFF1C3566),
    onPrimaryContainer: Color(0xFFD7E3FF),
    secondary: Color(0xFF4FD1B0),
    onSecondary: Color(0xFF04291F),
    secondaryContainer: Color(0xFF0E4538),
    onSecondaryContainer: Color(0xFFB7F5E4),
    tertiary: Color(0xFFB39CFF),
    onTertiary: Color(0xFF241156),
    tertiaryContainer: Color(0xFF362769),
    onTertiaryContainer: Color(0xFFE3DAFF),
    error: Color(0xFFFF8A8E),
    onError: Color(0xFF4A0A0C),
    errorContainer: Color(0xFF5A1A1D),
    onErrorContainer: Color(0xFFFFD9DA),
    surface: Color(0xFF0E1420),
    onSurface: Color(0xFFF2F5FB),
    surfaceContainerLowest: Color(0xFF0A0F18),
    surfaceContainerLow: Color(0xFF161E2C),
    surfaceContainer: Color(0xFF1A2333),
    surfaceContainerHigh: Color(0xFF202A3B),
    surfaceContainerHighest: Color(0xFF263246),
    onSurfaceVariant: Color(0xFFA7B2C6),
    outline: Color(0xFF6C7A91),
    outlineVariant: Color(0xFF2A3548),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF2F4F7),
    onInverseSurface: Color(0xFF1D2939),
    inversePrimary: Color(0xFF2F6BFF),
    surfaceTint: Color(0xFF7FA5FF),
  );

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final textTheme = _textTheme(base.textTheme, scheme);

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.8),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: scheme.outline),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        errorMaxLines: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.titleMedium?.copyWith(color: scheme.onPrimary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          side: BorderSide(color: scheme.outlineVariant, width: 1.2),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: scheme.primary,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      extensions: <ThemeExtension<dynamic>>[
        brightness == Brightness.light
            ? AppSemanticColors.light
            : AppSemanticColors.dark,
        brightness == Brightness.light ? AppNoteTones.light : AppNoteTones.dark,
      ],
    );
  }

  /// Thang chữ theo `14_ui_style_guide.png`: 32 / 24 / 16 / 14 / 12.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? style(
      TextStyle? source, {
      required double size,
      required FontWeight weight,
      double? height,
      double? letterSpacing,
    }) {
      return source?.copyWith(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: scheme.onSurface,
      );
    }

    return base.copyWith(
      displaySmall: style(
        base.displaySmall,
        size: 32,
        weight: FontWeight.w800,
        height: 1.18,
        letterSpacing: -0.8,
      ),
      headlineMedium: style(
        base.headlineMedium,
        size: 26,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.6,
      ),
      headlineSmall: style(
        base.headlineSmall,
        size: 22,
        weight: FontWeight.w800,
        height: 1.25,
        letterSpacing: -0.3,
      ),
      titleLarge: style(
        base.titleLarge,
        size: 20,
        weight: FontWeight.w700,
        height: 1.25,
      ),
      titleMedium: style(
        base.titleMedium,
        size: 16,
        weight: FontWeight.w700,
        height: 1.3,
      ),
      bodyLarge: style(
        base.bodyLarge,
        size: 16,
        weight: FontWeight.w400,
        height: 1.45,
      ),
      bodyMedium: style(
        base.bodyMedium,
        size: 14,
        weight: FontWeight.w400,
        height: 1.45,
      ),
      labelLarge: style(
        base.labelLarge,
        size: 14,
        weight: FontWeight.w700,
        height: 1.2,
      ),
      labelMedium: style(
        base.labelMedium,
        size: 12,
        weight: FontWeight.w600,
        height: 1.2,
      ),
      labelSmall: style(
        base.labelSmall,
        size: 11,
        weight: FontWeight.w500,
        height: 1.2,
      ),
    );
  }
}
