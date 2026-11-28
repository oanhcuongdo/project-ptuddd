import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/conversation_model.dart';
import '../styles/chat_styles.dart';
import 'room_streak_badge.dart';

/// Cột trái trong giao diện Chat (kiểu Messenger/Zalo) hiển thị danh sách
/// các phòng bạn đã tham gia để chuyển phòng nhanh mà không cần thoát ra ngoài.
class ChatConversationSidebar extends StatefulWidget {
  final List<ConversationModel> rooms;
  final String activeRoomId;
  final ValueChanged<ConversationModel> onSelectRoom;
  final VoidCallback onBack;

  const ChatConversationSidebar({
    super.key,
    required this.rooms,
    required this.activeRoomId,
    required this.onSelectRoom,
    required this.onBack,
  });

  @override
  State<ChatConversationSidebar> createState() =>
      _ChatConversationSidebarState();
}

class _ChatConversationSidebarState extends State<ChatConversationSidebar> {
  final _searchController = TextEditingController();
  String _searchText = '';
  String _filterType = 'all'; // all | group | direct

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (isToday) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }

  List<ConversationModel> get _filteredRooms {
    final q = _searchText.trim().toLowerCase();
    return widget.rooms.where((room) {
      if (_filterType == 'group' && !room.isGroup) return false;
      if (_filterType == 'direct' && room.isGroup) return false;
      if (q.isNotEmpty) {
        final hay =
            '${room.name} ${room.lastMessageText} ${room.targetLang}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _filteredRooms;

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          right: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header cột trái: nút Back về trang Phòng học + tiêu đề "Tin nhắn"
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, 14, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  tooltip: 'Quay lại danh sách phòng',
                  style: IconButton.styleFrom(
                    backgroundColor: ChatStyles.tealSoftBg,
                    foregroundColor: ChatStyles.tealDark,
                    fixedSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 19),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Không gian học',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ChatStyles.tealPillBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${widget.rooms.length} phòng',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: ChatStyles.tealDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ô tìm kiếm cuộc trò chuyện
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchText = val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cuộc trò chuyện...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchText = '');
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF3F6F8),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 3 pill lọc: Tất cả | Nhóm | Bạn bè
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _FilterTabPill(
                  label: 'Tất cả',
                  active: _filterType == 'all',
                  onTap: () => setState(() => _filterType = 'all'),
                ),
                _FilterTabPill(
                  label: 'Nhóm',
                  active: _filterType == 'group',
                  onTap: () => setState(() => _filterType = 'group'),
                ),
                _FilterTabPill(
                  label: 'Bạn bè',
                  active: _filterType == 'direct',
                  onTap: () => setState(() => _filterType = 'direct'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),

          // Danh sách phòng đã tham gia
          Expanded(
            child: rooms.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Không tìm thấy cuộc trò chuyện nào.',
                        textAlign: TextAlign.center,
                        style: ChatStyles.metaText,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, index) {
                      final room = rooms[index];
                      final isSelected = room.id == widget.activeRoomId;
                      return _RoomListItem(
                        room: room,
                        isSelected: isSelected,
                        timeText: _formatTime(room.lastMessageAt),
                        onTap: () => widget.onSelectRoom(room),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterTabPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ChatStyles.tealPrimary : const Color(0xFFF3F6F8),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RoomListItem extends StatelessWidget {
  final ConversationModel room;
  final bool isSelected;
  final String timeText;
  final VoidCallback onTap;

  const _RoomListItem({
    required this.room,
    required this.isSelected,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = ChatStyles.gradientForCoverKey(room.coverUrl) ??
        const [ChatStyles.tealDark, ChatStyles.tealLight];
    final hasImage =
        room.coverUrl != null && room.coverUrl!.startsWith('http');
    final preview = room.lastMessageText.trim().isNotEmpty
        ? room.lastMessageText.trim()
        : (room.description.trim().isNotEmpty
            ? room.description.trim()
            : 'Chưa có tin nhắn nào...');

    return Material(
      color: isSelected ? ChatStyles.tealSoftBg : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: const Color(0xFFF4F8F9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? ChatStyles.tealBorder : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // Avatar tròn phòng học + chấm xanh hoạt động
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
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
                                  : Icons.person_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                        : Icon(
                            room.isGroup
                                ? Icons.groups_rounded
                                : Icons.person_rounded,
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
              const SizedBox(width: 10),
              // Tên phòng + tin nhắn cuối + thời gian + đốm lửa nhỏ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: TextStyle(
                              fontSize: 13.8,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: isSelected
                                  ? ChatStyles.tealDeep
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeText.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        RoomStreakBadge(room: room, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
