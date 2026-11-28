import 'package:flutter/material.dart';

/// Hệ thống màu Burgundy chuyên nghiệp của ứng dụng:
///
/// Bảng màu thương hiệu Burgundy:
/// - [primary]:      #9F1239  Hành động chính, nút bấm, điểm nhấn phân cấp
/// - [deep]:         #500724  Sidebar đậm, header nền tối
/// - [secondary]:    #E8B4BC  Viền tinh tế, icon phụ, trạng thái tương tác
/// - [primaryLight]: #FFF5F5  Nền nhấn nhẹ, badge, icon container
/// - [accent]:       #D4A373  Điểm nhấn vàng nâu hợp lý
///
/// Màu trung tính chuyên nghiệp:
/// - [background]:      #FAF7F7  Nền phụ cho vùng nội dung chính
/// - [surface]:         #FFFFFF  Bề mặt Card, Dialog, Panel trắng
/// - [textPrimary]:     #1E293B  Tiêu đề, chữ đậm chính
/// - [textSecondary]:   #64748B  Nội dung phụ, nhãn, mô tả
/// - [textLight]:       #FFFFFF  Chữ trắng trên nền đậm
/// - [border]:          #E2E8F0  Đường viền mỏng tinh tế
///
/// Legacy aliases (dùng để tương thích, không dùng cho code mới):
/// - [primaryAction]  → primary
/// - [primaryBackground] → primaryLight
/// - [surfaceAlt]     → background
class AppColors {
  AppColors._();

  // === Thương hiệu Burgundy ===
  static const Color primary = Color(0xFF9F1239);
  static const Color deep = Color(0xFF500724);
  static const Color secondary = Color(0xFFE8B4BC);
  static const Color primaryLight = Color(0xFFFFF5F5);
  static const Color accent = Color(0xFFD4A373);

  // === Trung tính ===
  static const Color background = Color(0xFFFAF7F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // === Ngữ nghĩa ===
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  // === Legacy aliases (tương thích ngược) ===
  static const Color primaryAction = primary;
  static const Color primaryBackground = primaryLight;
  static const Color surfaceAlt = background;
}

/// Theme dùng chung toàn hệ thống, tuân thủ nguyên tắc phân cấp thị giác hiện đại.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textLight,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.textLight,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.background,
      outline: AppColors.secondary,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // Cấu hình AppBar: Nền trắng sạch, viền dưới mỏng, chữ đậm rõ nét
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),

      // Nút bấm chính (FilledButton) — Burgundy
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.textLight.withValues(alpha: 0.7),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Nút viền (OutlinedButton)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Nút chữ (TextButton)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Trường nhập liệu (TextFormField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card hiển thị: Viền mảnh tinh tế, không shadow
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
      ),

      // SnackBar
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),

      // FloatingActionButton — Burgundy
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
    );
  }
}
