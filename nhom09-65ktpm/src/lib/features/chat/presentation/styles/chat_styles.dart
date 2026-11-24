import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Style dùng riêng cho phân hệ Trò chuyện (Danh sách phòng & Thẻ phòng)
class ChatStyles {
  ChatStyles._();

  static const BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusLg)),
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.divider, width: 1),
    ),
  );

  static const BoxDecoration tabContainerDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.divider, width: 1),
    ),
  );

  static const TextStyle roomTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle roomDescription = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle metaText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );
}
