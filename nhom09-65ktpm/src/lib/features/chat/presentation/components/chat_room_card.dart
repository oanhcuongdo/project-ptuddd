import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/conversation_model.dart';
import '../styles/chat_styles.dart';

/// Thẻ hiển thị 1 Phòng Chat (dùng chung cho "Phòng của tôi" và "Khám phá phòng nhóm")
class ChatRoomCard extends StatelessWidget {
  final ConversationModel room;
  final bool isBusy;
  final VoidCallback onJoin;
  final VoidCallback onOpen;
  final VoidCallback? onLeave;

  const ChatRoomCard({
    super.key,
    required this.room,
    this.isBusy = false,
    required this.onJoin,
    required this.onOpen,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ChatStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: room.isGroup
                      ? const Color(0xFFEEF2FF)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  room.isGroup
                      ? Icons.groups_rounded
                      : Icons.person_outline_rounded,
                  color: room.isGroup
                      ? AppColors.primary
                      : const Color(0xFF0284C7),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: ChatStyles.roomTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _TagPill(
                          text: room.isGroup
                              ? '${room.targetLang.toUpperCase()} • ${room.level}'
                              : 'Chat 1-1',
                          bgColor: const Color(0xFFEEF2FF),
                          textColor: AppColors.primary,
                        ),
                        if (room.isGroup && room.topicCategory.isNotEmpty)
                          _TagPill(
                            text: room.topicCategory,
                            bgColor: const Color(0xFFF1F5F9),
                            textColor: AppColors.textSecondary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            room.isJoined && room.lastMessageText.isNotEmpty
                ? room.lastMessageText
                : (room.description.isNotEmpty
                    ? room.description
                    : 'Phòng luyện giao tiếp trực tuyến trên BuddyTalk.'),
            style: ChatStyles.roomDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (room.isGroup) ...[
                const Icon(
                  Icons.people_outline_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${room.memberCount} / ${room.maxMembers} thành viên',
                  style: ChatStyles.metaText,
                ),
              ],
              const Spacer(),
              if (room.isJoined && room.isGroup && onLeave != null) ...[
                IconButton(
                  onPressed: isBusy ? null : onLeave,
                  tooltip: 'Rời phòng',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.exit_to_app_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (room.isJoined)
                FilledButton.icon(
                  onPressed: isBusy ? null : onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Vào chat'),
                )
              else
                OutlinedButton(
                  onPressed: (isBusy || room.isFull) ? null : onJoin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(room.isFull ? 'Phòng đã đầy' : 'Tham gia phòng'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const _TagPill({
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
