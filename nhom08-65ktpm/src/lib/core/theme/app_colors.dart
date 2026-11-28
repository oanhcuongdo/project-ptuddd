import 'package:flutter/material.dart';

/// Hệ thống màu chuẩn trích xuất trực tiếp từ thiết kế Google Stitch của Travel Buddy.
/// Đã sửa lỗi tương phản onPrimary thành #FFFFFF và bổ sung màu nhấn cục bộ cho MoMo.
class AppColors {
  AppColors._();

  // Brand & Primary
  static const Color primary = Color(0xFF007AFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE5F1FF);
  static const Color onPrimaryContainer = Color(0xFF004999);

  // Secondary
  static const Color secondary = Color(0xFF5856D6);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFEDEDFA);
  static const Color onSecondaryContainer = Color(0xFF3634A3);

  // Semantic: Mint (Thành công / Đúng hạn)
  static const Color mint = Color(0xFF34C759);
  static const Color mintContainer = Color(0xFFE8F8EC);
  static const Color onMintContainer = Color(0xFF146C2E);

  // Semantic: Amber (Chờ duyệt / Cảnh báo)
  static const Color amber = Color(0xFFFF9500);
  static const Color amberContainer = Color(0xFFFFF4E5);
  static const Color onAmberContainer = Color(0xFF8A4B00);

  // Semantic: Error (Trễ hạn / Từ chối)
  static const Color error = Color(0xFFFF3B30);
  static const Color errorContainer = Color(0xFFFFEBEA);
  static const Color onErrorContainer = Color(0xFFB31B12);

  // MoMo Accent (chỉ dùng cục bộ cho badge & CTA mở MoMo)
  static const Color momo = Color(0xFFA50064);
  static const Color momoContainer = Color(0xFFFCE7F3);
  static const Color onMomoContainer = Color(0xFF831843);

  // Neutral Surfaces & Outlines
  static const Color surface = Color(0xFFF2F2F7);
  static const Color onSurface = Color(0xFF000000);
  static const Color surfaceContainerLow = Color(0xFFF9F9FB);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE5E5EA);
  static const Color surfaceContainerHighest = Color(0xFFD1D1D6);
  static const Color onSurfaceVariant = Color(0xFF6C6C70);
  static const Color outline = Color(0xFFAEAEB2);
  static const Color outlineVariant = Color(0xFFD1D1D6);
  static const Color outlineVariantSoft = Color(0x99D1D1D6);
}
