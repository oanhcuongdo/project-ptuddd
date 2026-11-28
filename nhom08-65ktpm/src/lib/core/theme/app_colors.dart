import 'package:flutter/material.dart';

/// Hệ thống màu Coastal Teal & Sunset Terracotta dùng thống nhất cho Travel Buddy.
/// Màu MoMo (#A50064 / momoTint) chỉ dùng cục bộ bên trong thẻ liên kết ví MoMo.
class AppColors {
  AppColors._();

  // Brand & Primary: Coastal Teal
  static const Color primary = Color(0xFF0F766E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFCCFBF1);
  static const Color onPrimaryContainer = Color(0xFF0D5C56);

  // Secondary: Sunset Terracotta
  static const Color secondary = Color(0xFFEA580C);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFFEDD5);
  static const Color onSecondaryContainer = Color(0xFF9A3412);
  static const Color terracotta = secondary;

  // Semantic: Mint / Emerald (Thành công / Đúng hạn)
  static const Color mint = Color(0xFF10B981);
  static const Color mintContainer = Color(0xFFD1FAE5);
  static const Color onMintContainer = Color(0xFF065F46);

  // Semantic: Amber (Chờ duyệt / Cảnh báo)
  static const Color amber = Color(0xFFD97706);
  static const Color amberContainer = Color(0xFFFEF3C7);
  static const Color onAmberContainer = Color(0xFF92400E);

  // Semantic: Danger Red (Vượt ngân sách / Trễ hạn / Từ chối)
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);
  static const Color dangerRed = error;

  // MoMo Accent (chỉ dùng cục bộ trong thẻ liên kết MoMo)
  static const Color momo = Color(0xFFA50064);
  static const Color momoTint = Color(0xFFFDF2F8);
  static const Color momoContainer = Color(0xFFFCE7F3);
  static const Color onMomoContainer = Color(0xFF831843);

  // Neutral Surfaces & Outlines
  static const Color surface = Color(0xFFF8FAFC);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color surfaceContainerLow = Color(0xFFFDFEFE);
  static const Color surfaceContainer = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFF1F5F9);
  static const Color surfaceContainerHighest = Color(0xFFE2E8F0);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color outline = Color(0xFF94A3B8);
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color outlineVariantSoft = Color(0x99CBD5E1);
}
