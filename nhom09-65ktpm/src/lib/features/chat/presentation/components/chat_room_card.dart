import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/conversation_model.dart';
import '../styles/chat_styles.dart';
import 'room_streak_badge.dart';

/// Thẻ Phòng học thiết kế theo phong cách Cover minh họa + Tông Xanh Ngọc hiện đại:
/// - Ảnh bìa gradient riêng theo ngôn ngữ kèm badge số thành viên & chuỗi lửa TikTok
/// - Thông tin phòng, người quản lý, yêu cầu trình độ/kiểm duyệt & nút hành động bo tròn
class ChatRoomCard extends StatelessWidget {
  final ConversationModel room;
  final bool isBusy;
  final bool isListMode;
  final VoidCallback onJoin;
  final VoidCallback onOpen;
  final VoidCallback? onLeave;
  final VoidCallback? onManageRequests;

  const ChatRoomCard({
    super.key,
    required this.room,
    this.isBusy = false,
    this.isListMode = false,
    required this.onJoin,
    required this.onOpen,
    this.onLeave,
    this.onManageRequests,
  });

  ({
    IconData icon,
    String coverWord,
    List<Color> gradient,
    Color accent,
    Color softBg,
  }) _themeForRoom() {
    if (!room.isGroup) {
      return (
        icon: Icons.person_outline_rounded,
        coverWord: '1-1 Chat',
        gradient: const [Color(0xFF0F766E), Color(0xFF0284C7)],
        accent: const Color(0xFF0284C7),
        softBg: const Color(0xFFE0F2FE),
      );
    }
    switch (room.targetLang.toLowerCase()) {
      case 'en':
        return (
          icon: Icons.headset_mic_rounded,
          coverWord: 'English',
          gradient: const [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF2DD4BF)],
          accent: ChatStyles.tealPrimary,
          softBg: ChatStyles.tealSoftBg,
        );
      case 'ja':
        return (
          icon: Icons.translate_rounded,
          coverWord: '日本語',
          gradient: const [Color(0xFF115E59), Color(0xFF0E7490), Color(0xFF38BDF8)],
          accent: const Color(0xFF0E7490),
          softBg: const Color(0xFFECFEFF),
        );
      case 'ko':
        return (
          icon: Icons.forum_rounded,
          coverWord: '한국어',
          gradient: const [Color(0xFF134E4A), Color(0xFF0D9488), Color(0xFF34D399)],
          accent: const Color(0xFF059669),
          softBg: const Color(0xFFECFDF5),
        );
      case 'zh':
        return (
          icon: Icons.language_rounded,
          coverWord: '中文',
          gradient: const [Color(0xFF0F766E), Color(0xFF15803D), Color(0xFF4ADE80)],
          accent: const Color(0xFF15803D),
          softBg: const Color(0xFFF0FDF4),
        );
      default:
        return (
          icon: Icons.menu_book_rounded,
          coverWord: room.targetLang.toUpperCase(),
          gradient: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
          accent: ChatStyles.tealPrimary,
          softBg: ChatStyles.tealSoftBg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themeForRoom();
    final customPresetGradient = ChatStyles.gradientForCoverKey(room.coverUrl);
    final coverGradient = customPresetGradient ?? theme.gradient;
    final hasCustomImage =
        room.coverUrl != null && room.coverUrl!.startsWith('http');

    if (isListMode) {
      return _buildListTile(theme, coverGradient);
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ChatStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh bìa minh họa đầu thẻ (hỗ trợ ảnh URL, nền preset hoặc mặc định theo ngôn ngữ)
          SizedBox(
            height: 108,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: coverGradient,
                    ),
                  ),
                ),
                if (hasCustomImage)
                  Image.network(
                    room.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                if (hasCustomImage)
                  Container(color: Colors.black.withValues(alpha: 0.24)),
                if (!hasCustomImage) ...[
                  Positioned(
                    left: -18,
                    bottom: -24,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -12,
                    top: -20,
                    child: Icon(
                      theme.icon,
                      size: 92,
                      color: Colors.white.withValues(alpha: 0.13),
                    ),
                  ),
                  Center(
                    child: Text(
                      theme.coverWord,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.92),
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                // Góc trái trên: Đốm lửa phòng (nếu đã tham gia) hoặc nhãn Ngôn ngữ
                Positioned(
                  left: 10,
                  top: 10,
                  child: room.isJoined
                      ? RoomStreakBadge(room: room, compact: true)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            room.isGroup
                                ? room.targetLang.toUpperCase()
                                : '1-1',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                // Góc phải trên: Pill tối mờ hiển thị số thành viên (giống mockup)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: room.memberCount > 0
                                ? const Color(0xFF4ADE80)
                                : AppColors.border,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${room.memberCount} thành viên',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Phần nội dung bên dưới ảnh bìa
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(theme.icon, size: 17, color: theme.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        room.name,
                        style: ChatStyles.roomTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (room.isGroup)
                      _TagPill(
                        text: room.levelLabel,
                        bgColor: room.hasLevelRequirement
                            ? const Color(0xFFFEF3C7)
                            : ChatStyles.tealSoftBg,
                        textColor: room.hasLevelRequirement
                            ? const Color(0xFFB45309)
                            : ChatStyles.tealDark,
                      ),
                    if (room.roomFocus != null && room.roomFocus!.isNotEmpty)
                      _TagPill(
                        text: room.roomFocus!,
                        bgColor: const Color(0xFFE0F2FE),
                        textColor: const Color(0xFF0369A1),
                      ),
                    if (room.isGroup && room.requireApproval)
                      const _TagPill(
                        text: 'Cần duyệt',
                        bgColor: Color(0xFFF3E8FF),
                        textColor: Color(0xFF7E22CE),
                      ),
                  ],
                ),
                if (room.isGroup && room.managerName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 13.5,
                        color: ChatStyles.tealPrimary,
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
                const SizedBox(height: 6),
                SizedBox(
                  height: 36,
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
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (room.isGroup)
                      Expanded(
                        child: Text(
                          room.memberSummary,
                          style: ChatStyles.metaText,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 6),
                    _buildActionControls(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    ({
      IconData icon,
      String coverWord,
      List<Color> gradient,
      Color accent,
      Color softBg,
    }) theme,
    List<Color> coverGradient,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: ChatStyles.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: coverGradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(theme.icon, color: Colors.white, size: 21),
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
                      bgColor: ChatStyles.tealSoftBg,
                      textColor: ChatStyles.tealDark,
                    ),
                    if (room.isJoined)
                      RoomStreakBadge(room: room, compact: true),
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
        if (room.canManageRoom &&
            room.isGroup &&
            room.pendingCount > 0 &&
            onManageRequests != null) ...[
          OutlinedButton.icon(
            onPressed: isBusy ? null : onManageRequests,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7E22CE),
              side: const BorderSide(color: Color(0xFFD8B4FE)),
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.how_to_reg_rounded, size: 14),
            label: Text('Duyệt (${room.pendingCount})'),
          ),
          const SizedBox(width: 6),
        ],
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
          const SizedBox(width: 2),
        ],
        if (room.isJoined)
          FilledButton(
            onPressed: isBusy ? null : onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: ChatStyles.tealPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Vào chat'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          )
        else if (room.isPending)
          OutlinedButton.icon(
            onPressed: isBusy ? null : onLeave,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              backgroundColor: const Color(0xFFFFFBEB),
              side: const BorderSide(color: Color(0xFFFCD34D)),
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.hourglass_top_rounded, size: 14),
            label: const Text('Chờ duyệt'),
          )
        else
          FilledButton(
            onPressed: (isBusy || room.isFull) ? null : onJoin,
            style: FilledButton.styleFrom(
              backgroundColor: ChatStyles.tealPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        room.isFull
                            ? 'Đã đầy'
                            : (room.requireApproval
                                ? 'Xin tham gia'
                                : 'Tham gia'),
                      ),
                      if (!room.isFull) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ],
                  ),
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
