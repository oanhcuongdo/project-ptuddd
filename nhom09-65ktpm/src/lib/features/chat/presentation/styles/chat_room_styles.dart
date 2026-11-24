import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Style dùng riêng cho giao diện bên trong Phòng Chat (Header, Khung tin nhắn, Composer)
class ChatRoomStyles {
  ChatRoomStyles._();

  static const BoxDecoration shellDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusLg)),
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.divider, width: 1),
    ),
  );

  static const BoxDecoration headerDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    border: Border(
      bottom: BorderSide(color: AppColors.divider, width: 1),
    ),
  );

  static const BoxDecoration composerDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    border: Border(
      top: BorderSide(color: AppColors.divider, width: 1),
    ),
  );

  static BoxDecoration messageBubble({required bool isMine}) {
    return BoxDecoration(
      color: isMine ? AppColors.primary : AppColors.surfaceWhite,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(isMine ? 16 : 4),
        bottomRight: Radius.circular(isMine ? 4 : 16),
      ),
      border: isMine ? null : Border.all(color: AppColors.divider),
    );
  }

  static const TextStyle roomHeaderTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle roomHeaderMeta = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
  );

  static TextStyle messageText({required bool isMine}) => TextStyle(
        fontSize: 14,
        height: 1.4,
        color: isMine ? Colors.white : AppColors.textPrimary,
      );
}
