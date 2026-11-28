import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/online_member_model.dart';
import '../styles/chat_styles.dart';

/// Cột cộng đồng bên phải trang Khám phá phòng học (100% dữ liệu thật từ Supabase):
/// 1. Phòng học sôi nổi (xếp hạng 1–5 theo số thành viên thực tế)
/// 2. Xếp hạng chuỗi cao (sắp xếp thành viên theo `streak_count` & `best_streak` giảm dần)
class ChatCommunitySidebar extends StatelessWidget {
  final List<ConversationModel> allRooms;
  final List<OnlineMemberModel> onlineMembers;
  final ValueChanged<ConversationModel> onSelectRoom;

  const ChatCommunitySidebar({
    super.key,
    required this.allRooms,
    required this.onlineMembers,
    required this.onSelectRoom,
  });

  static const _rankColors = [
    (bg: Color(0xFFFEE2E2), fg: Color(0xFFDC2626)),
    (bg: Color(0xFFCCFBF1), fg: Color(0xFF0F766E)),
    (bg: Color(0xFFFEF3C7), fg: Color(0xFFD97706)),
    (bg: Color(0xFFE0F2FE), fg: Color(0xFF0284C7)),
    (bg: Color(0xFFF3E8FF), fg: Color(0xFF7E22CE)),
  ];

  @override
  Widget build(BuildContext context) {
    final topRooms = List<ConversationModel>.from(allRooms)
      ..sort((a, b) => b.memberCount.compareTo(a.memberCount));
    final displayedTop = topRooms.take(5).toList();

    final topStreakMembers = List<OnlineMemberModel>.from(onlineMembers)
      ..sort((a, b) {
        final cmpStreak = b.streakCount.compareTo(a.streakCount);
        if (cmpStreak != 0) return cmpStreak;
        final cmpBest = b.bestStreak.compareTo(a.bestStreak);
        if (cmpBest != 0) return cmpBest;
        return a.displayName.compareTo(b.displayName);
      });
    final displayedMembers = topStreakMembers.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Bảng xếp hạng phòng học nổi bật
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: ChatStyles.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 19,
                    color: Color(0xFFF59E0B),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phòng học sôi nổi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (displayedTop.isEmpty)
                const Text(
                  'Chưa có phòng học nào.',
                  style: ChatStyles.metaText,
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < displayedTop.length; i++) ...[
                      _TopRoomRow(
                        rank: i + 1,
                        room: displayedTop[i],
                        colors: _rankColors[i % _rankColors.length],
                        onTap: () => onSelectRoom(displayedTop[i]),
                      ),
                      if (i < displayedTop.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Card 2: Bảng xếp hạng thành viên có chuỗi cao nhất từ Supabase
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: ChatStyles.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 19,
                    color: AppColors.streakOrange,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Xếp hạng chuỗi cao',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (displayedMembers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.streakBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Top ${displayedMembers.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (displayedMembers.isEmpty)
                const Text(
                  'Chưa có dữ liệu xếp hạng chuỗi thành viên.',
                  style: ChatStyles.metaText,
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < displayedMembers.length; i++) ...[
                      _TopStreakMemberRow(
                        rank: i + 1,
                        member: displayedMembers[i],
                        colors: _rankColors[i % _rankColors.length],
                      ),
                      if (i < displayedMembers.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopRoomRow extends StatelessWidget {
  final int rank;
  final ConversationModel room;
  final ({Color bg, Color fg}) colors;
  final VoidCallback onTap;

  const _TopRoomRow({
    required this.rank,
    required this.room,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.bg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.fg,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                room.name,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${room.memberCount} thành viên',
              style: ChatStyles.metaText,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopStreakMemberRow extends StatelessWidget {
  final int rank;
  final OnlineMemberModel member;
  final ({Color bg, Color fg}) colors;

  const _TopStreakMemberRow({
    required this.rank,
    required this.member,
    required this.colors,
  });

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'BT';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _initialsAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: ChatStyles.tealPillBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(member.displayName),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: ChatStyles.tealDark,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl =
        member.avatarUrl != null && member.avatarUrl!.startsWith('http');
    final hasStreak = member.streakCount > 0;
    final meta = member.bestStreak > member.streakCount
        ? '${member.targetLang} • ${member.proficiencyLevel} • Kỷ lục ${member.bestStreak}'
        : '${member.targetLang} • ${member.proficiencyLevel}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: colors.bg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: colors.fg,
            ),
          ),
        ),
        const SizedBox(width: 8),
        hasUrl
            ? ClipOval(
                child: Image.network(
                  member.avatarUrl!,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initialsAvatar(),
                ),
              )
            : _initialsAvatar(),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                meta,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (member.topRoomName != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.meeting_room_outlined,
                      size: 11.5,
                      color: ChatStyles.tealPrimary,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        'Phòng: ${member.topRoomName}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ChatStyles.tealDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: hasStreak ? AppColors.streakBg : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: hasStreak ? const Color(0xFFFDBA74) : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 13,
                color:
                    hasStreak ? AppColors.streakOrange : AppColors.textMuted,
              ),
              const SizedBox(width: 2),
              Text(
                '${member.streakCount}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: hasStreak
                      ? const Color(0xFFC2410C)
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
