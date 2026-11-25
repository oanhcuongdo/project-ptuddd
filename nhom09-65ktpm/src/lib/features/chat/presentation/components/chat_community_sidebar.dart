import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/online_member_model.dart';
import '../styles/chat_styles.dart';

/// Cột cộng đồng bên phải trang Khám phá phòng học (100% dữ liệu thật từ Supabase):
/// 1. Phòng học nổi bật (xếp hạng 1–5 theo số thành viên thực tế)
/// 2. Thành viên đang online (truy vấn thật từ `profiles.is_online = true`)
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

        // Card 2: Thành viên đang online thật từ Supabase
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: ChatStyles.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bạn bè đang online',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (onlineMembers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ChatStyles.tealPillBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${onlineMembers.length}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: ChatStyles.tealDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (onlineMembers.isEmpty)
                const Text(
                  'Hiện chưa có thêm thành viên nào đang trực tuyến.',
                  style: ChatStyles.metaText,
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < onlineMembers.length; i++) ...[
                      _OnlineMemberRow(member: onlineMembers[i]),
                      if (i < onlineMembers.length - 1)
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
              '${room.memberCount} tv',
              style: ChatStyles.metaText,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineMemberRow extends StatelessWidget {
  final OnlineMemberModel member;

  const _OnlineMemberRow({required this.member});

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'BT';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _initialsAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: ChatStyles.tealPillBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(member.displayName),
        style: const TextStyle(
          fontSize: 12,
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

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            hasUrl
                ? ClipOval(
                    child: Image.network(
                      member.avatarUrl!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialsAvatar(),
                    ),
                  )
                : _initialsAvatar(),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.displayName,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Đang học ${member.targetLang} • ${member.proficiencyLevel}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
