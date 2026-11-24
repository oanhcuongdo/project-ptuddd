import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/app_error_text.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';
import '../../data/models/conversation_model.dart';
import '../components/chat_room_card.dart';
import '../providers/chat_provider.dart';
import '../styles/chat_styles.dart';

/// Màn hình Danh sách Phòng Chat (Đợt 1):
/// - Tab 1: Phòng của tôi (Chat 1-1 & Nhóm đã tham gia)
/// - Tab 2: Khám phá phòng nhóm (tìm theo tên, lọc ngôn ngữ từ DB & trình độ A1–B2, Tham gia/Rời phòng)
class ChatRoomsTab extends StatefulWidget {
  const ChatRoomsTab({super.key});

  @override
  State<ChatRoomsTab> createState() => _ChatRoomsTabState();
}

class _ChatRoomsTabState extends State<ChatRoomsTab> {
  final _searchController = TextEditingController();
  int _activeTab = 0; // 0: Phòng của tôi, 1: Khám phá phòng nhóm
  String? _loadedForUserId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _ensureLoaded(String? userId) {
    if (userId == null || userId == _loadedForUserId) return;
    _loadedForUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChatProvider>().loadRooms(userId);
      }
    });
  }

  void _openRoomPlaceholder(ConversationModel room) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã sẵn sàng vào phòng "${room.name}" — khung nhắn tin Realtime sẽ mở ở đợt tiếp theo.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentProfile?.userId;
    final chat = context.watch<ChatProvider>();
    _ensureLoaded(userId);

    final rooms = _activeTab == 0 ? chat.myRooms : chat.discoverRooms;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopTabBar(chat, userId),
          if (_activeTab == 1) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildFilterBar(chat, userId),
          ],
          AppErrorText(message: chat.errorMessage),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _buildRoomList(chat, rooms, userId),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabBar(ChatProvider chat, String? userId) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: ChatStyles.tabContainerDecoration,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _SegmentButton(
                label: 'Phòng của tôi (${chat.myRooms.length})',
                isActive: _activeTab == 0,
                onTap: () => setState(() => _activeTab = 0),
              ),
              _SegmentButton(
                label: 'Khám phá phòng nhóm (${chat.discoverRooms.length})',
                isActive: _activeTab == 1,
                onTap: () => setState(() => _activeTab = 1),
              ),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: (chat.isLoading || userId == null)
              ? null
              : () => chat.loadRooms(userId),
          tooltip: 'Tải lại danh sách phòng',
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
    );
  }

  Widget _buildFilterBar(ChatProvider chat, String? userId) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm tên phòng học nhóm...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
            ),
            onSubmitted: (val) {
              if (userId != null) {
                chat.applyFilters(userId: userId, searchQuery: val);
              }
            },
          ),
        ),
        DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: ChatStyles.tabContainerDecoration,
            child: DropdownButton<String?>(
              value: chat.selectedLang,
              hint: const Text('Ngôn ngữ: Tất cả'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Ngôn ngữ: Tất cả'),
                ),
                ...chat.languages.map(
                  (lang) => DropdownMenuItem<String?>(
                    value: lang.code,
                    child: Text('${lang.flagCode} ${lang.shortLabel}'),
                  ),
                ),
              ],
              onChanged: (val) {
                if (userId == null) return;
                chat.applyFilters(
                  userId: userId,
                  targetLang: val,
                  clearLang: val == null,
                );
              },
            ),
          ),
        ),
        DropdownButtonHideUnderline(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: ChatStyles.tabContainerDecoration,
            child: DropdownButton<String?>(
              value: chat.selectedLevel,
              hint: const Text('Trình độ: Tất cả'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Trình độ: Tất cả'),
                ),
                ...AppConstants.proficiencyLevels.map(
                  (lvl) => DropdownMenuItem<String?>(
                    value: lvl,
                    child: Text('Trình độ: $lvl'),
                  ),
                ),
              ],
              onChanged: (val) {
                if (userId == null) return;
                chat.applyFilters(
                  userId: userId,
                  level: val,
                  clearLevel: val == null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomList(
    ChatProvider chat,
    List<ConversationModel> rooms,
    String? userId,
  ) {
    if (chat.isLoading && rooms.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _activeTab == 0
                  ? 'Bạn chưa tham gia phòng trò chuyện nào.'
                  : 'Chưa có phòng học nhóm nào phù hợp bộ lọc.',
              style: ChatStyles.roomTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _activeTab == 0
                  ? 'Chuyển sang tab "Khám phá phòng nhóm" để chọn phòng bạn thích và tham gia ngay.'
                  : 'Dữ liệu được tải trực tiếp từ bảng conversations trên Supabase.',
              style: ChatStyles.roomDescription,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        if (!isWide) {
          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, index) => _buildCard(chat, rooms[index], userId),
          );
        }

        final cardWidth = (constraints.maxWidth - AppSpacing.lg) / 2;
        return SingleChildScrollView(
          child: Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: rooms
                .map(
                  (room) => SizedBox(
                    width: cardWidth,
                    child: _buildCard(chat, room, userId),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildCard(
    ChatProvider chat,
    ConversationModel room,
    String? userId,
  ) {
    return ChatRoomCard(
      room: room,
      isBusy: chat.busyRoomId == room.id,
      onOpen: () => _openRoomPlaceholder(room),
      onJoin: () async {
        if (userId == null) return;
        final ok = await chat.joinRoom(conversationId: room.id, userId: userId);
        if (mounted && ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã tham gia phòng "${room.name}"!')),
          );
        }
      },
      onLeave: userId == null
          ? null
          : () => chat.leaveRoom(conversationId: room.id, userId: userId),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
