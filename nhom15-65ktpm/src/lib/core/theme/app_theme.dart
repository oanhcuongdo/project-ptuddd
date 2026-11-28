import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Hệ thống Theme dùng chung cho toàn bộ ứng dụng Finger Math Soroban Kids.
///
/// Thiết kế theo chuẩn Zero-Text UI:
/// - Kiểu chữ Quicksand thân thiện, bo tròn, dễ đọc cho trẻ 4–6 tuổi và phụ huynh.
/// - Độ tương phản màu sắc đạt chuẩn WCAG AA trên mọi thành phần giao diện.
/// - Kích thước touch target tối thiểu 48x48dp đảm bảo trẻ dễ bấm chính xác.
/// - Tương thích hoàn toàn trên Mobile, Web Chrome và Windows Desktop.
class AppTheme {
  // ===========================================================================
  // 1. GIAO DIỆN HỌC TẬP CỦA TRẺ (Child UI Theme / Kid Theme)
  // ===========================================================================
  static ThemeData get kidTheme => childTheme;

  static ThemeData get childTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: const Color(0xFFFFDDD5),
      onPrimaryContainer: const Color(0xFF5C1608),
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: const Color(0xFFFFF3C4),
      onSecondaryContainer: const Color(0xFF352900),
      tertiary: AppColors.accentPurple,
      onTertiary: AppColors.onAccentPurple,
      tertiaryContainer: const Color(0xFFEDE3FF),
      onTertiaryContainer: const Color(0xFF2E1065),
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: AppColors.background,
      onSurface: AppColors.textDark,
      onSurfaceVariant: AppColors.textLight,
      outline: AppColors.textLight,
      outlineVariant: AppColors.outline,
    );

    final textTheme = _buildTextTheme(AppColors.textDark, AppColors.textLight);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // Thanh điều hướng trên cùng (AppBar)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),

      // Thẻ Card dùng chung (KidCard / Material Card)
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),

      // Hộp thoại (Dialog)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
      ),

      // Khay trượt từ dưới lên (Modal Bottom Sheet)
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // Dải phân cách (Divider)
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),

      // Thanh tiến độ (Progress Indicator)
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surface,
        circularTrackColor: AppColors.surface,
      ),

      // Nút gạt bật/tắt (Switch)
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.35);
          }
          return AppColors.surface;
        }),
      ),

      // Nút bấm chính (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1.5,
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.textDark,
          minimumSize: const Size(
            AppDimensions.minTouchSize,
            AppDimensions.buttonHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          textStyle: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Nút bấm viền (OutlinedButton)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          minimumSize: const Size(
            AppDimensions.minTouchSize,
            AppDimensions.minTouchSize,
          ),
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      ),

      // Nút bấm chữ (TextButton)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          minimumSize: const Size(
            AppDimensions.minTouchSize,
            AppDimensions.minTouchSize,
          ),
        ),
      ),

      // Nút bấm dạng đầy (FilledButton)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.textDark,
          elevation: 1.5,
          minimumSize: const Size(
            AppDimensions.minTouchSize,
            AppDimensions.buttonHeight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      ),

      // Nút bấm Icon (IconButton)
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppDimensions.minTouchSize,
            AppDimensions.minTouchSize,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      ),

      // Khung nhập liệu (InputDecoration)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBg,
        hintStyle: textTheme.bodyMedium,
        labelStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primaryText, width: 2),
        ),
        errorStyle: TextStyle(color: colorScheme.error),
      ),

      // Thông báo nổi (SnackBar)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. GIAO DIỆN QUẢN LÝ CỦA PHỤ HUYNH (Parent UI Theme)
  // ===========================================================================
  /// Theme dành riêng cho Parent Dashboard với phong cách thanh lịch, trực quan
  static ThemeData get parentTheme {
    final base = childTheme;
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.parentSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.parentCardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. XÂY DỰNG TEXT THEME QUICKSAND
  // ===========================================================================
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return GoogleFonts.quicksandTextTheme().copyWith(
      displayLarge: GoogleFonts.quicksand(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: primaryColor,
      ),
      displayMedium: GoogleFonts.quicksand(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      titleLarge: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      titleMedium: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      bodyLarge: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      bodySmall: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      labelLarge: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
    );
  }
}
