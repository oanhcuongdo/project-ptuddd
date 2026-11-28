import 'package:flutter/material.dart';

/// Bảng màu chuẩn hóa theo quy tắc 60-30-10 & độ tương phản WCAG AA (>= 4.5:1):
/// - 60%: Nền sáng thoáng (#F3F6FB) & bề mặt thẻ trắng (#FFFFFF)
/// - 30%: Xanh hải quân / xanh dương tin cậy (#0F4C81, #1565C0, #1E88E5)
/// - 10%: Cam cứu hộ / sửa xe năng động (#F97316) & Đỏ khẩn cấp SOS (#DC2626)
abstract final class AppColors {
  static const navyDeep = Color(0xFF0A2540);
  static const navyBrand = Color(0xFF0F4C81);
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF1E88E5);
  static const skyAccent = Color(0xFF38BDF8);

  static const motoOrange = Color(0xFFF97316);
  static const motoAmber = Color(0xFFFB923C);

  static const sosRed = Color(0xFFDC2626);
  static const sosRedDark = Color(0xFFB91C1C);

  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFECFDF5);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFFFBEB);
  static const dangerBg = Color(0xFFFEF2F2);
  static const infoBg = Color(0xFFEFF6FF);

  static const canvas = Color(0xFFF3F6FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const inkPrimary = Color(0xFF0F172A);
  static const inkSecondary = Color(0xFF475569);
  static const inkMuted = Color(0xFF64748B);

  static const heroGradient = LinearGradient(
    colors: [navyDeep, navyBrand, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const primaryButtonGradient = LinearGradient(
    colors: [navyBrand, primaryLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// Giao diện thống nhất toàn ứng dụng theo tiêu chuẩn Tương tác Người-Máy (HCI):
/// phân cấp thị giác rõ ràng, vùng chạm >= 48dp (Fitts's Law), độ tương phản cao,
/// và trạng thái ngữ nghĩa đồng nhất kèm biểu tượng (không chỉ dựa vào màu sắc).
ThemeData buildAppTheme() {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  );

  final scheme = baseScheme.copyWith(
    primary: AppColors.primary,
    secondary: AppColors.motoOrange,
    tertiary: AppColors.navyBrand,
    error: AppColors.sosRed,
    surface: AppColors.surface,
    onSurface: AppColors.inkPrimary,
    onSurfaceVariant: AppColors.inkSecondary,
    outlineVariant: AppColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.inkPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: AppColors.inkPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.inkPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 1.45,
        color: AppColors.inkPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: AppColors.inkPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12.5,
        height: 1.35,
        color: AppColors.inkSecondary,
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.inkPrimary,
      titleTextStyle: TextStyle(
        color: AppColors.inkPrimary,
        fontSize: 18.5,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceMuted,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(
        color: AppColors.inkSecondary,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(color: AppColors.inkMuted, fontSize: 13.5),
      prefixIconColor: AppColors.inkSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.sosRed, width: 1.3),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.sosRed, width: 1.8),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        side: const BorderSide(color: AppColors.border, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceMuted,
      selectedColor: scheme.primaryContainer,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 4,
      shadowColor: AppColors.navyDeep.withValues(alpha: 0.08),
      surfaceTintColor: Colors.white,
      indicatorColor: AppColors.infoBg,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.inkSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 23,
          color: selected ? AppColors.primary : AppColors.inkSecondary,
        );
      }),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.inkSecondary,
      indicatorColor: AppColors.primary,
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 13.5,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navyDeep,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

/// Nhãn trạng thái kèm biểu tượng + màu sắc ngữ nghĩa (đảm bảo WCAG không chỉ dựa vào màu).
Widget buildStatusBadge(String status) {
  final (label, bg, fg, icon) = switch (status) {
    'approved' => (
        'Đã duyệt',
        AppColors.successBg,
        const Color(0xFF047857),
        Icons.verified_rounded,
      ),
    'active' => (
        'Hoạt động',
        AppColors.successBg,
        const Color(0xFF047857),
        Icons.check_circle_rounded,
      ),
    'pending' => (
        'Chờ duyệt',
        AppColors.warningBg,
        const Color(0xFFB45309),
        Icons.hourglass_top_rounded,
      ),
    'rejected' => (
        'Bị từ chối',
        AppColors.dangerBg,
        const Color(0xFFB91C1C),
        Icons.cancel_rounded,
      ),
    'banned' => (
        'Đã khóa',
        const Color(0xFFF1F5F9),
        const Color(0xFF334155),
        Icons.lock_rounded,
      ),
    _ => (
        status,
        const Color(0xFFF1F5F9),
        const Color(0xFF334155),
        Icons.info_outline_rounded,
      ),
  };

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: fg.withValues(alpha: 0.22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.5, color: fg),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
