import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/app_error_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';
import '../../data/models/conversation_model.dart';
import '../components/chat_filter_panel.dart';
import '../components/chat_pagination_bar.dart';
import '../components/chat_room_card.dart';
import '../components/create_room_dialog.dart';
import '../components/pending_requests_dialog.dart';
import '../providers/chat_provider.dart';
import '../styles/chat_styles.dart';
import 'chat_room_view.dart';

/// Màn hình Danh sách & Khám phá Phòng học Realtime:
/// - Thanh tiêu đề + chuyển tab Phòng của tôi / Khám phá + nút "+ Tạo phòng mới"
/// - Khung lọc nhanh (Tìm kiếm, chip Ngôn ngữ từ DB, Trình độ, Chủ đề)
/// - Thanh công cụ Sắp xếp, Số phòng/trang, chuyển chế độ Lưới / Danh sách & Phân trang
class ChatRoomsTab extends StatefulWidget {
  const ChatRoomsTab({super.key});

  @override
  State<ChatRoomsTab> createState() => _ChatRoomsTabState();
}

class _ChatRoomsTabState extends State<ChatRoomsTab> {
  final _searchController = TextEditingController();

  int _activeTab = 0; // 0: Phòng của tôi, 1: Khám phá phòng học
  String? _loadedForUserId;
  ConversationModel? _openedRoom;

  // Bộ lọc & phân trang hiển thị
  String _searchText = '';
  String? _selectedLang;
  String? _selectedLevel;
  bool _onlyAvailable = false;
  String _sortBy = 'popular'; // popular | newest
  int _pageSize = 6;
  int _currentPage = 1;
  bool _isGridView = true;

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

  Future<void> _openCreateRoomDialog(
    ChatProvider chat,
    String userId,
    String managerName,
  ) async {
    final created = await showDialog<ConversationModel>(
      context: context,
      builder: (_) => CreateRoomDialog(
        createdBy: userId,
        managerName: managerName,
        languages: chat.languages,
      ),
    );
    if (!mounted || created == null) return;
    setState(() {
      _activeTab = 0;
      _currentPage = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF047857),
        content: Text('Đã tạo phòng "${created.name}" thành công!'),
      ),
    );
  }

  List<ConversationModel> _filterAndSort(List<ConversationModel> source) {
    final q = _searchText.trim().toLowerCase();
    final filtered = source.where((room) {
      if (_selectedLang != null && room.targetLang != _selectedLang) {
        return false;
      }
      if (_selectedLevel == ChatFilterPanel.noLevelFilterValue) {
        if (room.hasLevelRequirement) return false;
      } else if (_selectedLevel != null && room.level != _selectedLevel) {
        return false;
      }
      if (_onlyAvailable && room.isFull) {
        return false;
      }
      if (q.isNotEmpty) {
        final hay =
            '${room.name} ${room.managerName} ${room.targetLang} ${room.description}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    if (_sortBy == 'popular') {
      filtered.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().currentProfile;
    final userId = profile?.userId;
    final managerName = profile?.displayName ?? '';
    final chat = context.watch<ChatProvider>();
    _ensureLoaded(userId);

    if (_openedRoom != null) {
      return ChatRoomView(
        room: _openedRoom!,
        onBack: () => setState(() => _openedRoom = null),
        onLeaveRoom: userId == null
            ? null
            : () async {
                final roomId = _openedRoom!.id;
                final ok = await chat.leaveRoom(
                  conversationId: roomId,
                  userId: userId,
                );
                if (mounted && ok) {
                  setState(() => _openedRoom = null);
                }
              },
      );
    }

    final rawRooms = _activeTab == 0 ? chat.myRooms : chat.discoverRooms;
    final filtered = _filterAndSort(rawRooms);
    final totalItems = filtered.length;
    final totalPages = totalItems == 0 ? 1 : (totalItems / _pageSize).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _pageSize;
    final endIdx = (startIdx + _pageSize).clamp(0, totalItems);
    final pageRooms = totalItems == 0
        ? const <ConversationModel>[]
        : filtered.sublist(startIdx, endIdx);

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderAndActions(chat, userId, managerName, rawRooms.length),
              const SizedBox(height: AppSpacing.lg),
              ChatFilterPanel(
                searchController: _searchController,
                languages: chat.languages,
                selectedLang: _selectedLang,
                selectedLevel: _selectedLevel,
                onlyAvailable: _onlyAvailable,
                onSearchChanged: (val) => setState(() {
                  _searchText = val;
                  _currentPage = 1;
                }),
                onLangSelected: (lang) => setState(() {
                  _selectedLang = lang;
                  _currentPage = 1;
                }),
                onLevelSelected: (lvl) => setState(() {
                  _selectedLevel = lvl;
                  _currentPage = 1;
                }),
                onOnlyAvailableChanged: (val) => setState(() {
                  _onlyAvailable = val;
                  _currentPage = 1;
                }),
              ),
              AppErrorText(message: chat.errorMessage),
              const SizedBox(height: AppSpacing.lg),
              _buildListToolbar(
                totalItems: totalItems,
                startDisplay: totalItems == 0 ? 0 : startIdx + 1,
                endDisplay: endIdx,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildRoomsSection(chat, pageRooms, userId),
              if (totalItems > 0) ...[
                const SizedBox(height: AppSpacing.lg),
                ChatPaginationBar(
                  currentPage: safePage,
                  totalPages: totalPages,
                  onPageChanged: (p) => setState(() => _currentPage = p),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAndActions(
    ChatProvider chat,
    String? userId,
    String managerName,
    int totalInTab,
  ) {
    final title = _activeTab == 0 ? 'Phòng của tôi' : 'Khám phá phòng học';
    final subtitle = _activeTab == 0
        ? 'Các phòng Chat 1-1 và phòng học nhóm bạn đã tham gia ($totalInTab phòng)'
        : 'Lọc nhanh theo ngôn ngữ và trình độ trong kho $totalInTab phòng học';

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ChatStyles.pageTitle),
              const SizedBox(height: 4),
              Text(subtitle, style: ChatStyles.pageSubtitle),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: ChatStyles.controlBoxDecoration,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _TabChip(
                      label: 'Phòng của tôi (${chat.myRooms.length})',
                      isActive: _activeTab == 0,
                      onTap: () => setState(() {
                        _activeTab = 0;
                        _currentPage = 1;
                      }),
                    ),
                    _TabChip(
                      label: 'Khám phá (${chat.discoverRooms.length})',
                      isActive: _activeTab == 1,
                      onTap: () => setState(() {
                        _activeTab = 1;
                        _currentPage = 1;
                      }),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: (chat.isLoading || userId == null)
                    ? null
                    : () => _openCreateRoomDialog(chat, userId, managerName),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tạo phòng mới'),
              ),
              IconButton.outlined(
                onPressed: (chat.isLoading || userId == null)
                    ? null
                    : () => chat.loadRooms(userId),
                tooltip: 'Tải lại danh sách phòng',
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 19),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListToolbar({
    required int totalItems,
    required int startDisplay,
    required int endDisplay,
  }) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Text(
          totalItems == 0
              ? 'Không tìm thấy phòng nào'
              : 'Hiển thị $startDisplay–$endDisplay trong tổng số $totalItems phòng',
          style: ChatStyles.metaText,
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _ToolbarDropdown<String>(
              value: _sortBy,
              items: const [
                DropdownMenuItem(value: 'popular', child: Text('Phổ biến nhất')),
                DropdownMenuItem(value: 'newest', child: Text('Mới nhất')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _sortBy = v);
              },
            ),
            _ToolbarDropdown<int>(
              value: _pageSize,
              items: const [
                DropdownMenuItem(value: 6, child: Text('6 phòng / trang')),
                DropdownMenuItem(value: 12, child: Text('12 phòng / trang')),
                DropdownMenuItem(value: 24, child: Text('24 phòng / trang')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _pageSize = v;
                    _currentPage = 1;
                  });
                }
              },
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: ChatStyles.controlBoxDecoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ViewToggleBtn(
                    icon: Icons.grid_view_rounded,
                    label: 'Lưới',
                    isActive: _isGridView,
                    onTap: () => setState(() => _isGridView = true),
                  ),
                  _ViewToggleBtn(
                    icon: Icons.view_list_rounded,
                    label: 'Danh sách',
                    isActive: !_isGridView,
                    onTap: () => setState(() => _isGridView = false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomsSection(
    ChatProvider chat,
    List<ConversationModel> rooms,
    String? userId,
  ) {
    if (chat.isLoading && rooms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (rooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: ChatStyles.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 46,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _activeTab == 0
                  ? 'Bạn chưa tham gia phòng học nào.'
                  : 'Chưa có phòng học nhóm nào phù hợp bộ lọc.',
              style: ChatStyles.roomTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Bấm "+ Tạo phòng mới" hoặc chuyển sang tab Khám phá để tham gia phòng ngay.',
              style: ChatStyles.roomDescription,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isGridView) {
      return Column(
        children: rooms
            .map(
              (room) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _buildCard(chat, room, userId, isListMode: true),
              ),
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 1060
            ? 3
            : (constraints.maxWidth >= 660 ? 2 : 1);
        const spacing = AppSpacing.lg;
        final cardWidth = (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: rooms
              .map(
                (room) => SizedBox(
                  width: cardWidth,
                  child: _buildCard(chat, room, userId, isListMode: false),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Future<void> _openPendingRequests(
    ConversationModel room,
    String userId,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => PendingRequestsDialog(
        room: room,
        currentUserId: userId,
      ),
    );
  }

  Widget _buildCard(
    ChatProvider chat,
    ConversationModel room,
    String? userId, {
    required bool isListMode,
  }) {
    return ChatRoomCard(
      room: room,
      isListMode: isListMode,
      isBusy: chat.busyRoomId == room.id,
      onOpen: () => setState(() => _openedRoom = room),
      onManageRequests: userId == null
          ? null
          : () => _openPendingRequests(room, userId),
      onJoin: () async {
        if (userId == null) return;
        final ok = await chat.joinRoom(
          conversationId: room.id,
          userId: userId,
          requireApproval: room.requireApproval,
        );
        if (mounted && ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                room.requireApproval
                    ? 'Đã gửi yêu cầu xin tham gia "${room.name}" — vui lòng chờ quản lý duyệt!'
                    : 'Đã tham gia phòng "${room.name}"!',
              ),
            ),
          );
        }
      },
      onLeave: userId == null
          ? null
          : () => chat.leaveRoom(conversationId: room.id, userId: userId),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

class _ToolbarDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _ToolbarDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: ChatStyles.controlBoxDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggleBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
