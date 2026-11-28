import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'chat_styles.dart';

/// Style dùng riêng cho giao diện bên trong Phòng Chat (đồng bộ tông Xanh Ngọc)
class ChatRoomStyles {
  ChatRoomStyles._();

  static final BoxDecoration shellDecoration = BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.radiusLg)),
    border: const Border.fromBorderSide(
      BorderSide(color: AppColors.divider, width: 1),
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
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
      gradient: isMine
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ChatStyles.tealPrimary, ChatStyles.tealDark],
            )
          : null,
      color: isMine ? null : AppColors.surfaceWhite,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(18),
        topRight: const Radius.circular(18),
        bottomLeft: Radius.circular(isMine ? 18 : 4),
        bottomRight: Radius.circular(isMine ? 4 : 18),
      ),
      border: isMine ? null : Border.all(color: const Color(0xFFE2ECEE)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: isMine ? 0.08 : 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static const TextStyle roomHeaderTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
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
