import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Style dùng riêng cho màn hình Danh sách & Khám phá phòng học (BuddyTalk)
class ChatStyles {
  ChatStyles._();

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    border: Border.all(color: AppColors.divider, width: 1),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static const BoxDecoration controlBoxDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.all(Radius.circular(10)),
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.divider, width: 1),
    ),
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 13.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle roomTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle roomDescription = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const TextStyle metaText = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}
