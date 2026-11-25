import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Bộ Style tông Xanh Ngọc (Teal / Emerald) dùng riêng cho khu vực Trò chuyện & Khám phá phòng học.
class ChatStyles {
  ChatStyles._();

  // Tông màu Xanh Ngọc chủ đạo (thay cho màu tím trên mockup)
  static const Color tealPrimary = Color(0xFF0D9488);
  static const Color tealDark = Color(0xFF0F766E);
  static const Color tealDeep = Color(0xFF115E59);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color tealSoftBg = Color(0xFFF0FDFA);
  static const Color tealPillBg = Color(0xFFCCFBF1);
  static const Color tealBorder = Color(0xFF99F6E4);

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE6EEF2), width: 1),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.045),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static const BoxDecoration controlBoxDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0xFFE2E8F0), width: 1),
    ),
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 13.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle roomTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle roomDescription = TextStyle(
    fontSize: 12.8,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle metaText = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const double cardRadius = AppSpacing.radiusLg;
}
