import 'package:flutter/material.dart';

/// Hệ thống màu chuẩn hóa và phối màu trung tính cao cấp của ứng dụng:
/// 
/// 4 mã màu thương hiệu bắt buộc:
/// - [primaryBackground]: #EBEAFF (Chỉ dùng làm nền nhấn nhẹ, badge, icon container)
/// - [secondary]: #9694FF (Dùng cho đường viền tinh tế, icon phụ, trạng thái tương tác)
/// - [primaryAction]: #3D3BF3 (Hành động chính, nút bấm, điểm nhấn phân cấp; không phủ kín diện tích lớn)
/// - [danger]: #FF2929 (Cảnh báo, lỗi, hành động nguy hiểm/đăng xuất)
/// 
/// Màu trung tính chuyên nghiệp:
/// - [surface]: #FFFFFF (Bề mặt chính cho Scaffold, Card, Sidebar, Dialog)
/// - [surfaceAlt]: #F9F9FD (Bề mặt phụ siêu nhẹ giúp tạo chiều sâu nhẹ nhàng)
/// - [textPrimary]: #25234A (Tiêu đề, chữ đậm chính, độ tương phản cao, dễ đọc)
/// - [textSecondary]: #6B6985 (Nội dung phụ, nhãn, mô tả)
/// - [textLight]: #FFFFFF (Chữ trắng trên nút/nền đậm)
/// - [border]: #E2E1F8 (Đường viền mỏng tinh tế, nhẹ nhàng hơn)
class AppColors {
  AppColors._();

  // 4 mã màu thương hiệu
  static const Color primaryBackground = Color(0xFFEBEAFF);
  static const Color secondary = Color(0xFF9694FF);
  static const Color primaryAction = Color(0xFF3D3BF3);
  static const Color danger = Color(0xFFFF2929);

  // Bảng màu trung tính chuẩn hóa theo yêu cầu
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF9F9FD);
  static const Color textPrimary = Color(0xFF25234A); // Tiêu đề
  static const Color textSecondary = Color(0xFF6B6985); // Nội dung phụ
  static const Color textLight = Colors.white;
  static const Color border = Color(0xFFE2E1F8); // Viền nhẹ
  static const Color borderSubtle = Color(0xFFEDEDFA);
}

/// Theme dùng chung toàn hệ thống, tuân thủ nguyên tắc phân cấp thị giác hiện đại.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryAction,
      onPrimary: AppColors.textLight,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textLight,
      error: AppColors.danger,
      onError: AppColors.textLight,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceAlt,
      outline: AppColors.secondary,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface, // Dùng nền trắng sạch sẽ

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

      // Nút bấm chính (FilledButton)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryAction,
          foregroundColor: AppColors.textLight,
          disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.35),
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
          foregroundColor: AppColors.primaryAction,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Nút chữ (TextButton)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryAction,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Trường nhập liệu (TextFormField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.primaryAction, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 14),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card hiển thị: Viền mảnh tinh tế, giảm shadow thô
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

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryAction,
        foregroundColor: AppColors.textLight,
      ),
    );
  }
}
