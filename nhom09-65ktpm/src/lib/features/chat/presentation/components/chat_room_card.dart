import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/conversation_model.dart';
import '../styles/chat_styles.dart';

/// Thẻ hiển thị 1 Phòng học (Lưới & Danh sách) — gồm Ngôn ngữ, Yêu cầu trình độ,
/// Người quản lý phòng, mô tả, số thành viên (giới hạn hoặc không giới hạn) & nút hành động.
class ChatRoomCard extends StatelessWidget {
  final ConversationModel room;
  final bool isBusy;
  final bool isListMode;
  final VoidCallback onJoin;
  final VoidCallback onOpen;
  final VoidCallback? onLeave;

  const ChatRoomCard({
    super.key,
    required this.room,
    this.isBusy = false,
    this.isListMode = false,
    required this.onJoin,
    required this.onOpen,
    this.onLeave,
  });

  (IconData, Color, Color) _langIconStyle() {
    if (!room.isGroup) {
      return (
        Icons.person_outline_rounded,
        const Color(0xFF0284C7),
        const Color(0xFFE0F2FE),
      );
    }
    switch (room.targetLang.toLowerCase()) {
      case 'en':
        return (
          Icons.groups_rounded,
          const Color(0xFF4F46E5),
          const Color(0xFFEEF2FF),
        );
      case 'ja':
        return (
          Icons.translate_rounded,
          const Color(0xFFE11D48),
          const Color(0xFFFFE4E6),
        );
      case 'ko':
        return (
          Icons.forum_outlined,
          const Color(0xFF9333EA),
          const Color(0xFFF3E8FF),
        );
      case 'zh':
        return (
          Icons.language_rounded,
          const Color(0xFFD97706),
          const Color(0xFFFEF3C7),
        );
      default:
        return (
          Icons.menu_book_outlined,
          const Color(0xFF0D9488),
          const Color(0xFFCCFBF1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, iconBg) = _langIconStyle();

    if (isListMode) {
      return _buildListTile(icon, iconColor, iconBg);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ChatStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _TagPill(
                      text: room.isGroup
                          ? room.targetLang.toUpperCase()
                          : 'Chat 1-1',
                      bgColor: const Color(0xFFEEF2FF),
                      textColor: AppColors.primary,
                    ),
                    if (room.isGroup)
                      _TagPill(
                        text: room.levelLabel,
                        bgColor: room.hasLevelRequirement
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFECFDF5),
                        textColor: room.hasLevelRequirement
                            ? const Color(0xFFB45309)
                            : const Color(0xFF047857),
                      ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: room.memberCount > 0
                      ? const Color(0xFF16A34A)
                      : AppColors.border,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            room.name,
            style: ChatStyles.roomTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (room.isGroup && room.managerName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 13.5,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Quản lý: ${room.managerName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: Text(
              room.isJoined && room.lastMessageText.isNotEmpty
                  ? room.lastMessageText
                  : (room.description.isNotEmpty
                      ? room.description
                      : 'Không gian luyện giao tiếp trực tuyến thân thiện trên BuddyTalk.'),
              style: ChatStyles.roomDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (room.isGroup) ...[
                const Icon(
                  Icons.people_outline_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    room.memberSummary,
                    style: ChatStyles.metaText,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              _buildActionControls(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, Color iconColor, Color iconBg) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: ChatStyles.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(room.name, style: ChatStyles.roomTitle),
                    _TagPill(
                      text: room.isGroup
                          ? '${room.targetLang.toUpperCase()} • ${room.levelLabel}'
                          : 'Chat 1-1',
                      bgColor: const Color(0xFFEEF2FF),
                      textColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  room.isGroup
                      ? '${room.managerName.isNotEmpty ? "Quản lý: ${room.managerName}  •  " : ""}${room.memberSummary}'
                      : (room.lastMessageText.isNotEmpty
                          ? room.lastMessageText
                          : 'Phòng trò chuyện 1-1'),
                  style: ChatStyles.metaText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _buildActionControls(),
        ],
      ),
    );
  }

  Widget _buildActionControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          FilledButton(
            onPressed: isBusy ? null : onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Vào chat'),
          )
        else
          OutlinedButton(
            onPressed: (isBusy || room.isFull) ? null : onJoin,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(room.isFull ? 'Đã đầy' : 'Tham gia'),
          ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
