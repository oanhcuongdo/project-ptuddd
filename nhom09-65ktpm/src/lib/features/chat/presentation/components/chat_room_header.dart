import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/conversation_model.dart';
import '../styles/chat_room_styles.dart';
import '../styles/chat_styles.dart';
import 'room_streak_badge.dart';

/// Thanh đầu trang bên trong Phòng Chat (tông Xanh Ngọc):
/// Avatar phòng + chấm xanh, thông tin phòng, đốm lửa chuỗi phòng, nút Bắt đầu luyện & Rời phòng.
class ChatRoomHeader extends StatelessWidget {
  final ConversationModel room;
  final VoidCallback onBack;
  final bool showBackButton;
  final bool isInfoPanelOpen;
  final bool canScheduleMeet;
  final bool hasLiveMeet;
  final bool isAutoTranslateEnabled;
  final VoidCallback onToggleInfoPanel;
  final VoidCallback onMeetActionTap;
  final VoidCallback? onToggleAutoTranslate;

  const ChatRoomHeader({
    super.key,
    required this.room,
    required this.onBack,
    this.showBackButton = true,
    this.isInfoPanelOpen = false,
    this.canScheduleMeet = false,
    this.hasLiveMeet = false,
    this.isAutoTranslateEnabled = false,
    required this.onToggleInfoPanel,
    required this.onMeetActionTap,
    this.onToggleAutoTranslate,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = ChatStyles.gradientForCoverKey(room.coverUrl) ??
        const [ChatStyles.tealDark, ChatStyles.tealLight];
    final hasImage =
        room.coverUrl != null && room.coverUrl!.startsWith('http');

    final subtitleParts = <String>[
      if (room.isGroup)
        '${room.targetLang.toUpperCase()} • ${room.levelLabel}'
      else
        'Chat 1-1',
      if (room.roomFocus != null && room.roomFocus!.isNotEmpty) room.roomFocus!,
      if (room.isGroup) room.memberSummary,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: ChatRoomStyles.headerDecoration,
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              onPressed: onBack,
              tooltip: 'Quay lại danh sách phòng',
              style: IconButton.styleFrom(
                backgroundColor: ChatStyles.tealSoftBg,
                foregroundColor: ChatStyles.tealDark,
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
                child: hasImage
                    ? Image.network(
                        room.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          room.isGroup
                              ? Icons.groups_rounded
                              : Icons.person_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                    : Icon(
                        room.isGroup
                            ? Icons.groups_rounded
                            : Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
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
          if (onToggleAutoTranslate != null) ...[
            Tooltip(
              message: isAutoTranslateEnabled
                  ? 'Đang bật Tự động dịch tin nhắn đến (bấm để tắt)'
                  : 'Bật Tự động dịch toàn bộ tin nhắn đến',
              child: InkWell(
                onTap: onToggleAutoTranslate,
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAutoTranslateEnabled
                        ? ChatStyles.tealPrimary
                        : ChatStyles.tealSoftBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isAutoTranslateEnabled
                          ? ChatStyles.tealPrimary
                          : ChatStyles.tealBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.translate_rounded,
                        size: 15,
                        color: isAutoTranslateEnabled
                            ? Colors.white
                            : ChatStyles.tealDark,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isAutoTranslateEnabled ? 'Tự dịch: BẬT' : 'Tự dịch',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isAutoTranslateEnabled
                              ? Colors.white
                              : ChatStyles.tealDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          RoomStreakBadge(room: room),
          if (hasLiveMeet || canScheduleMeet) ...[
            const SizedBox(width: AppSpacing.sm),
            hasLiveMeet
                ? FilledButton.icon(
                    onPressed: onMeetActionTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: ChatStyles.tealPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.videocam_rounded, size: 17),
                    label: const Text('Vào Meet'),
                  )
                : OutlinedButton.icon(
                    onPressed: onMeetActionTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ChatStyles.tealDark,
                      backgroundColor: ChatStyles.tealSoftBg,
                      side: const BorderSide(color: ChatStyles.tealBorder),
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.video_call_rounded, size: 17),
                    label: const Text('Hẹn lịch Meet'),
                  ),
          ],
          const SizedBox(width: 6),
          IconButton(
            onPressed: onToggleInfoPanel,
            tooltip: 'Thông tin phòng',
            style: IconButton.styleFrom(
              backgroundColor: isInfoPanelOpen
                  ? ChatStyles.tealSoftBg
                  : Colors.transparent,
              foregroundColor: isInfoPanelOpen
                  ? ChatStyles.tealPrimary
                  : AppColors.textSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isInfoPanelOpen
                      ? ChatStyles.tealBorder
                      : Colors.transparent,
                ),
              ),
            ),
            icon: Icon(
              isInfoPanelOpen
                  ? Icons.view_sidebar_rounded
                  : Icons.view_sidebar_outlined,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}
