import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/conversation_model.dart';
import '../styles/chat_room_styles.dart';

/// Thanh đầu trang bên trong Phòng Chat:
/// Nút quay lại, thông tin phòng (ngôn ngữ, trình độ, số thành viên) và nút slot Timer / Rời phòng.
class ChatRoomHeader extends StatelessWidget {
  final ConversationModel room;
  final VoidCallback onBack;
  final VoidCallback onStartSessionTap;
  final VoidCallback? onLeaveRoom;

  const ChatRoomHeader({
    super.key,
    required this.room,
    required this.onBack,
    required this.onStartSessionTap,
    this.onLeaveRoom,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (room.isGroup) '${room.targetLang.toUpperCase()} • ${room.level}' else 'Chat 1-1',
      if (room.isGroup && room.topicCategory.isNotEmpty) room.topicCategory,
      if (room.isGroup) '${room.memberCount}/${room.maxMembers} thành viên',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: ChatRoomStyles.headerDecoration,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Quay lại danh sách phòng',
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              room.isGroup ? Icons.groups_rounded : Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: ChatRoomStyles.roomHeaderTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleParts.join('  •  '),
                  style: ChatRoomStyles.roomHeaderMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onStartSessionTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.streakOrange,
              side: BorderSide(
                color: AppColors.streakOrange.withValues(alpha: 0.4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.timer_outlined, size: 17),
            label: const Text('Bắt đầu luyện'),
          ),
          if (room.isGroup && onLeaveRoom != null) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: onLeaveRoom,
              tooltip: 'Rời phòng',
              icon: const Icon(
                Icons.exit_to_app_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
