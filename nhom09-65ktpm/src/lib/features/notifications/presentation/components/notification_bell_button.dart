import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/layouts/styles/main_layout_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';
import '../../../chat/data/models/conversation_model.dart';
import '../../../chat/presentation/components/pending_requests_dialog.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';

/// Nút chuông thông báo Realtime trên MainHeader.
/// Bấm vào sẽ xổ bảng thông báo ngay dưới nút chuông (kiểu Facebook, không popup tối màn hình)
/// và tự động đồng bộ lại danh sách phòng chat khi có sự kiện duyệt / xin tham gia Realtime.
class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({super.key});

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final GlobalKey _bellKey = GlobalKey();
  String? _syncedUserId;
  double? _bellLeftDx;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.watch<AuthProvider>().currentProfile?.userId;
    if (userId != _syncedUserId) {
      _syncedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<NotificationProvider>().bindUser(
              userId,
              onRealtimeEvent: _handleRealtimeSync,
            );
      });
    }
  }

  /// Tự động cập nhật danh sách phòng phía dưới ngay khi nhận thông báo liên quan đến phòng học
  void _handleRealtimeSync(NotificationModel notification) {
    if (!mounted) return;
    final userId = _syncedUserId;
    if (userId == null) return;

    const roomEvents = {
      'room_join_request',
      'room_join_approved',
      'room_join_rejected',
    };
    if (roomEvents.contains(notification.type)) {
      context.read<ChatProvider>().loadRooms(userId, silent: true);
    }
  }

  void _toggleDropdown() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    } else {
      final box = _bellKey.currentContext?.findRenderObject() as RenderBox?;
      _bellLeftDx = box?.localToGlobal(Offset.zero).dx;
      _overlayController.show();
    }
    setState(() {});
  }

  void _closeDropdown() {
    if (!_overlayController.isShowing) return;
    _overlayController.hide();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;
    final userId = context.watch<AuthProvider>().currentProfile?.userId;
    final isOpen = _overlayController.isShowing;
    final badgeText = unread > 9 ? '9+' : '$unread';

    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (overlayContext) {
        final screenWidth = MediaQuery.sizeOf(overlayContext).width;
        final isCompact = screenWidth < 520;
        final rightMargin = isCompact ? 12.0 : AppSpacing.xl;

        // Căn trái ngay mép nút chuông và kéo sang phải thẳng hàng mép khu vực tài khoản
        final spanFromBell = _bellLeftDx != null
            ? (screenWidth - _bellLeftDx! - rightMargin)
            : 320.0;
        final panelWidth = isCompact
            ? (screenWidth - 24.0)
            : spanFromBell.clamp(280.0, 380.0);

        final panel = Material(
          color: Colors.transparent,
          child: _FacebookNotificationDropdown(
            currentUserId: userId ?? '',
            width: panelWidth,
            onClose: _closeDropdown,
          ),
        );

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
              ),
            ),
            Positioned(
              top: MainLayoutStyles.headerHeight + 6,
              right: rightMargin,
              width: panelWidth,
              child: panel,
            ),
          ],
        );
      },
      child: KeyedSubtree(
        key: _bellKey,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: userId == null ? null : _toggleDropdown,
              tooltip: 'Thông báo',
              style: IconButton.styleFrom(
                backgroundColor: isOpen
                    ? const Color(0xFFEEF2FF)
                    : AppColors.surfaceWhite,
                side: BorderSide(
                  color: isOpen ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fixedSize: const Size(38, 38),
                padding: EdgeInsets.zero,
              ),
              icon: Icon(
                isOpen || unread > 0
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded,
                size: 20,
                color: isOpen || unread > 0
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            if (unread > 0)
              Positioned(
                right: -3,
                top: -3,
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bảng xổ xuống ngay dưới chuông thông báo — thiết kế theo phong cách Facebook.
class _FacebookNotificationDropdown extends StatefulWidget {
  final String currentUserId;
  final double width;
  final VoidCallback onClose;

  const _FacebookNotificationDropdown({
    required this.currentUserId,
    required this.width,
    required this.onClose,
  });

  @override
  State<_FacebookNotificationDropdown> createState() =>
      _FacebookNotificationDropdownState();
}

class _FacebookNotificationDropdownState
    extends State<_FacebookNotificationDropdown> {
  bool _onlyUnread = false;

  String _formatRelativeTime(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt.toLocal());
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    final d = createdAt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  ({IconData icon, IconData badgeIcon, Color fg, Color bg}) _styleForType(
    String type,
  ) {
    switch (type) {
      case 'room_join_request':
        return (
          icon: Icons.groups_rounded,
          badgeIcon: Icons.person_add_alt_1_rounded,
          fg: const Color(0xFF7C3AED),
          bg: const Color(0xFFF3E8FF),
        );
      case 'room_join_approved':
      case 'room_join_handled_approved':
        return (
          icon: Icons.groups_rounded,
          badgeIcon: Icons.check_rounded,
          fg: const Color(0xFF059669),
          bg: const Color(0xFFECFDF5),
        );
      case 'room_join_rejected':
      case 'room_join_handled_rejected':
        return (
          icon: Icons.groups_rounded,
          badgeIcon: Icons.close_rounded,
          fg: AppColors.error,
          bg: const Color(0xFFFEF2F2),
        );
      default:
        return (
          icon: Icons.notifications_rounded,
          badgeIcon: Icons.bolt_rounded,
          fg: AppColors.primary,
          bg: const Color(0xFFEEF2FF),
        );
    }
  }

  Future<void> _handleTapItem(NotificationModel item) async {
    final notifProvider = context.read<NotificationProvider>();
    final chatProvider = context.read<ChatProvider>();
    final hostContext = context;

    if (!item.isRead) {
      notifProvider.markAsRead(item.id);
    }

    if (item.isRoomJoinRequest && item.referenceId != null) {
      final roomId = item.referenceId!;
      ConversationModel? foundRoom;
      for (final r in [
        ...chatProvider.myRooms,
        ...chatProvider.discoverRooms,
      ]) {
        if (r.id == roomId) {
          foundRoom = r;
          break;
        }
      }

      final targetRoom = foundRoom ??
          ConversationModel(
            id: roomId,
            type: 'group',
            name: 'Phòng học chờ duyệt',
            createdBy: widget.currentUserId,
            requireApproval: true,
          );

      widget.onClose();
      await showDialog<void>(
        context: hostContext,
        builder: (_) => PendingRequestsDialog(
          room: targetRoom,
          currentUserId: widget.currentUserId,
        ),
      );
      return;
    }

    if (item.type == 'room_join_approved' ||
        item.type == 'room_join_rejected') {
      chatProvider.loadRooms(widget.currentUserId, silent: true);
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final displayed = _onlyUnread
        ? provider.items.where((n) => !n.isRead).toList()
        : provider.items;

    return Container(
      width: widget.width,
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header giống Facebook: "Thông báo" + nút Đọc tất cả + Tải lại
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Thông báo',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (provider.unreadCount > 0)
                  TextButton(
                    onPressed: provider.markAllAsRead,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Đọc tất cả',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () {
                    provider.refresh(widget.currentUserId);
                    context
                        .read<ChatProvider>()
                        .loadRooms(widget.currentUserId, silent: true);
                  },
                  tooltip: 'Tải lại thông báo',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 2 tab pill kiểu Facebook: Tất cả | Chưa đọc
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _FilterPill(
                  label: 'Tất cả',
                  selected: !_onlyUnread,
                  onTap: () => setState(() => _onlyUnread = false),
                ),
                _FilterPill(
                  label: provider.unreadCount > 0
                      ? 'Chưa đọc (${provider.unreadCount})'
                      : 'Chưa đọc',
                  selected: _onlyUnread,
                  onTap: () => setState(() => _onlyUnread = true),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Nội dung danh sách thông báo
          if (provider.isLoading && displayed.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (displayed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 34,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 38,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _onlyUnread
                        ? 'Bạn đã đọc hết thông báo.'
                        : 'Chưa có thông báo nào.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Thông báo xin tham gia & duyệt phòng sẽ tự động hiện tại đây.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                itemCount: displayed.length,
                itemBuilder: (_, index) {
                  final item = displayed[index];
                  final style = _styleForType(item.type);

                  return Material(
                    color: item.isRead
                        ? Colors.transparent
                        : const Color(0xFFF3F6FF),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _handleTapItem(item),
                      borderRadius: BorderRadius.circular(12),
                      hoverColor: const Color(0xFFF1F5F9),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar tròn + badge nhỏ góc dưới phải (giống Facebook)
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: style.bg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    style.icon,
                                    size: 22,
                                    color: style.fg,
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: style.fg,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      style.badgeIcon,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Nội dung + thời gian
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: AppColors.textPrimary,
                                        height: 1.35,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${item.title}: ',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(
                                          text: item.body,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        _formatRelativeTime(item.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: item.isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          color: item.isRead
                                              ? AppColors.textMuted
                                              : AppColors.primary,
                                        ),
                                      ),
                                      if (item.isRoomJoinRequest)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3E8FF),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: const Text(
                                            'Xem & Duyệt',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF7C3AED),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Chấm xanh chưa đọc bên phải (kiểu Facebook)
                            if (!item.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
