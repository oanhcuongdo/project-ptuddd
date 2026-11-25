import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/room_member_model.dart';
import '../providers/chat_provider.dart';
import '../styles/chat_styles.dart';
import 'pending_requests_dialog.dart';
import 'room_streak_badge.dart';

/// Bảng Thông tin phòng bên phải (kiểu Zalo tông sáng Xanh Ngọc):
/// - Tóm tắt phòng + tác vụ nhanh (Duyệt thành viên, Sửa nội quy)
/// - Danh sách Thành viên (Chủ phòng / Phó phòng Trợ giảng / Thành viên) kèm phân quyền
/// - Link đã chia sẻ trong phòng (trích xuất thật từ lịch sử tin nhắn)
/// - Nút Rời phòng màu đỏ ở cuối bảng
class ChatRoomInfoPanel extends StatefulWidget {
  final ConversationModel room;
  final String? currentUserId;
  final List<MessageModel> messages;
  final VoidCallback onClose;
  final VoidCallback? onLeaveRoom;

  const ChatRoomInfoPanel({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.messages,
    required this.onClose,
    this.onLeaveRoom,
  });

  @override
  State<ChatRoomInfoPanel> createState() => _ChatRoomInfoPanelState();
}

class _ChatRoomInfoPanelState extends State<ChatRoomInfoPanel> {
  bool _membersExpanded = true;
  bool _rulesExpanded = true;
  bool _linksExpanded = true;

  List<String> _extractLinks() {
    final regex = RegExp(r'https?://[^\s]+', caseSensitive: false);
    final links = <String>[];
    for (final msg in widget.messages.reversed) {
      for (final match in regex.allMatches(msg.content)) {
        final url = match.group(0);
        if (url != null && !links.contains(url)) {
          links.add(url);
        }
      }
      if (links.length >= 8) break;
    }
    return links;
  }

  Future<void> _openEditDescriptionDialog() async {
    final ctrl = TextEditingController(text: widget.room.description);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Cập nhật mô tả / nội quy phòng',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 380,
          child: TextField(
            controller: ctrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Nhập nội quy, lịch luyện hoặc ghi chú cho cả phòng...',
              filled: true,
              fillColor: const Color(0xFFF8FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: ChatStyles.tealPrimary,
            ),
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final ok = await context.read<ChatProvider>().updateRoomDescription(
            conversationId: widget.room.id,
            description: ctrl.text,
          );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: ChatStyles.tealDark,
            content: Text('Đã cập nhật nội quy phòng học!'),
          ),
        );
      }
    }
    ctrl.dispose();
  }

  Future<void> _confirmLeaveRoom() async {
    if (widget.onLeaveRoom == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Rời khỏi phòng học?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Bạn có chắc muốn rời phòng "${widget.room.name}"? Chuỗi lửa của bạn với phòng này sẽ không được tiếp tục.',
          style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rời phòng'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onLeaveRoom?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final members = chat.roomMembers;
    final currentUid = widget.currentUserId;
    final links = _extractLinks();

    // Xác định vai trò thật của bản thân trong phòng (ưu tiên từ danh sách members vừa tải)
    var amOwner = widget.room.isOwner;
    var amCoOwner = widget.room.isCoOwner;
    if (currentUid != null) {
      for (final m in members) {
        if (m.userId == currentUid) {
          amOwner = m.isOwner;
          amCoOwner = m.isCoOwner;
          break;
        }
      }
    }
    final canManage = amOwner || amCoOwner;

    final gradient = ChatStyles.gradientForCoverKey(widget.room.coverUrl) ??
        const [ChatStyles.tealDark, ChatStyles.tealLight];
    final hasImage =
        widget.room.coverUrl != null && widget.room.coverUrl!.startsWith('http');

    return Container(
      width: 312,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          left: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header "Thông tin phòng" giống Zalo
          Container(
            height: 67,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Thông tin phòng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  tooltip: 'Đóng thông tin phòng',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // Avatar & Tên phòng căn giữa (kiểu Zalo)
                Center(
                  child: Container(
                    width: 66,
                    height: 66,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ChatStyles.tealPrimary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: hasImage
                        ? Image.network(
                            widget.room.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.groups_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          )
                        : const Icon(
                            Icons.groups_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.room.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniInfoTag(
                      '${widget.room.targetLang.toUpperCase()} • ${widget.room.levelLabel}',
                    ),
                    if (widget.room.roomFocus != null &&
                        widget.room.roomFocus!.isNotEmpty)
                      _MiniInfoTag(widget.room.roomFocus!),
                    RoomStreakBadge(room: widget.room, compact: true),
                  ],
                ),

                // Hàng nút tác vụ nhanh (giống hàng 3-4 icon tròn Zalo)
                if (canManage && widget.room.isGroup) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (currentUid != null)
                        _QuickCircleAction(
                          icon: Icons.how_to_reg_rounded,
                          label: widget.room.pendingCount > 0
                              ? 'Duyệt (${widget.room.pendingCount})'
                              : 'Kiểm duyệt',
                          highlight: widget.room.pendingCount > 0,
                          onTap: () => showDialog<void>(
                            context: context,
                            builder: (_) => PendingRequestsDialog(
                              room: widget.room,
                              currentUserId: currentUid,
                            ),
                          ),
                        ),
                      _QuickCircleAction(
                        icon: Icons.edit_note_rounded,
                        label: 'Sửa nội quy',
                        onTap: _openEditDescriptionDialog,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.divider),

                // Mục 1: Thành viên phòng (Chủ phòng, Phó phòng Trợ giảng, Thành viên)
                _CollapsibleSectionHeader(
                  title:
                      'Thành viên phòng (${members.isNotEmpty ? members.length : widget.room.memberCount})',
                  expanded: _membersExpanded,
                  onTap: () =>
                      setState(() => _membersExpanded = !_membersExpanded),
                ),
                if (_membersExpanded) ...[
                  if (chat.isLoadingMembers && members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ChatStyles.tealPrimary,
                          ),
                        ),
                      ),
                    )
                  else if (members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Đang cập nhật danh sách thành viên...',
                        style: ChatStyles.metaText,
                      ),
                    )
                  else
                    Column(
                      children: members.map((member) {
                        final isMe = member.userId == currentUid;
                        final canOwnerManageThis =
                            amOwner && !isMe && !member.isOwner;
                        final canCoOwnerKickThis =
                            amCoOwner && !isMe && member.isMember;

                        return _MemberRow(
                          member: member,
                          isMe: isMe,
                          canAssignCoOwner: canOwnerManageThis,
                          canKick: canOwnerManageThis || canCoOwnerKickThis,
                          onToggleCoOwner: () async {
                            if (currentUid == null) return;
                            final nextRole =
                                member.isCoOwner ? 'member' : 'co_owner';
                            final ok = await chat.setMemberRole(
                              conversationId: widget.room.id,
                              targetUserId: member.userId,
                              newRole: nextRole,
                              actorId: currentUid,
                              roomName: widget.room.name,
                            );
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: ChatStyles.tealDark,
                                  content: Text(
                                    nextRole == 'co_owner'
                                        ? 'Đã bổ nhiệm ${member.displayName} làm Trợ giảng!'
                                        : 'Đã gỡ quyền Trợ giảng của ${member.displayName}.',
                                  ),
                                ),
                              );
                            }
                          },
                          onKick: () async {
                            if (currentUid == null) return;
                            final ok = await chat.kickMember(
                              conversationId: widget.room.id,
                              targetUserId: member.userId,
                              currentUserId: currentUid,
                            );
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã mời ${member.displayName} ra khỏi phòng.',
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                ],

                const Divider(height: 1, color: AppColors.divider),

                // Mục 2: Bảng tin & Nội quy phòng
                _CollapsibleSectionHeader(
                  title: 'Nội quy & Quy định',
                  expanded: _rulesExpanded,
                  onTap: () => setState(() => _rulesExpanded = !_rulesExpanded),
                ),
                if (_rulesExpanded) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2ECEE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.room.description.isNotEmpty
                              ? widget.room.description
                              : 'Chưa có nội quy riêng. Giữ văn minh và luyện nói đều đặn mỗi ngày nhé!',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Chế độ vào phòng: ${widget.room.requireApproval ? "Cần kiểm duyệt" : "Vào ngay"}\n'
                          '• Sức chứa: ${widget.room.memberSummary}',
                          style: const TextStyle(
                            fontSize: 11.8,
                            color: AppColors.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 1, color: AppColors.divider),

                // Mục 3: Link đã chia sẻ trong phòng (trích xuất thật từ messages)
                _CollapsibleSectionHeader(
                  title: 'Link đã chia sẻ (${links.length})',
                  expanded: _linksExpanded,
                  onTap: () => setState(() => _linksExpanded = !_linksExpanded),
                ),
                if (_linksExpanded) ...[
                  if (links.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Chưa có đường link nào được chia sẻ trong phòng.',
                        style: ChatStyles.metaText,
                      ),
                    )
                  else
                    Column(
                      children: links
                          .map(
                            (url) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: ChatStyles.tealSoftBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.link_rounded,
                                      size: 16,
                                      color: ChatStyles.tealPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      url,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: ChatStyles.tealDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],

                if (widget.room.isGroup && widget.onLeaveRoom != null) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _confirmLeaveRoom,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.exit_to_app_rounded,
                            size: 19,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Rời phòng',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleSectionHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;

  const _CollapsibleSectionHeader({
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCircleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  final VoidCallback onTap;

  const _QuickCircleAction({
    required this.icon,
    required this.label,
    this.highlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: highlight
                    ? const Color(0xFFF3E8FF)
                    : ChatStyles.tealSoftBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 19,
                color: highlight
                    ? const Color(0xFF7E22CE)
                    : ChatStyles.tealDark,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final RoomMemberModel member;
  final bool isMe;
  final bool canAssignCoOwner;
  final bool canKick;
  final VoidCallback onToggleCoOwner;
  final VoidCallback onKick;

  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.canAssignCoOwner,
    required this.canKick,
    required this.onToggleCoOwner,
    required this.onKick,
  });

  String _initials(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'B';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _avatar() {
    Widget fallback() => Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: member.isOwner
                ? const Color(0xFFFEF3C7)
                : (member.isCoOwner
                    ? const Color(0xFFE0F2FE)
                    : ChatStyles.tealPillBg),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(member.displayName),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: member.isOwner
                  ? const Color(0xFFB45309)
                  : (member.isCoOwner
                      ? const Color(0xFF0369A1)
                      : ChatStyles.tealDark),
            ),
          ),
        );

    final url = member.avatarUrl;
    if (url == null || !url.startsWith('http')) return fallback();
    return ClipOval(
      child: Image.network(
        url,
        width: 34,
        height: 34,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showMenu = canAssignCoOwner || canKick;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _avatar(),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMe ? '${member.displayName} (Bạn)' : member.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.effectiveStreak > 0) ...[
                      const SizedBox(width: 5),
                      Text(
                        '🔥${member.effectiveStreak}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.streakOrange,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 5,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (member.isOwner)
                      const _RoleChip(
                        label: 'Chủ phòng',
                        bg: Color(0xFFFEF3C7),
                        fg: Color(0xFFB45309),
                      )
                    else if (member.isCoOwner)
                      const _RoleChip(
                        label: 'Trợ giảng',
                        bg: Color(0xFFE0F2FE),
                        fg: Color(0xFF0369A1),
                      ),
                    Text(
                      member.proficiencyLevel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showMenu)
            PopupMenuButton<String>(
              tooltip: 'Tùy chọn thành viên',
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              onSelected: (value) {
                if (value == 'toggle_co_owner') {
                  onToggleCoOwner();
                } else if (value == 'kick') {
                  onKick();
                }
              },
              itemBuilder: (_) => [
                if (canAssignCoOwner)
                  PopupMenuItem<String>(
                    value: 'toggle_co_owner',
                    child: Row(
                      children: [
                        Icon(
                          member.isCoOwner
                              ? Icons.person_remove_outlined
                              : Icons.school_outlined,
                          size: 17,
                          color: ChatStyles.tealDark,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            member.isCoOwner
                                ? 'Gỡ quyền Trợ giảng'
                                : 'Phân làm Trợ giảng',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (canKick)
                  const PopupMenuItem<String>(
                    value: 'kick',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 17,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Mời ra khỏi phòng',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _RoleChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _MiniInfoTag extends StatelessWidget {
  final String text;

  const _MiniInfoTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ChatStyles.tealSoftBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ChatStyles.tealDark,
        ),
      ),
    );
  }
}
