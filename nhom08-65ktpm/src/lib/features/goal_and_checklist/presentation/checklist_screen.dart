import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/local_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../models/trip_member.dart';
import '../../../models/trip_model.dart';
import '../../auth_and_group/providers/auth_providers.dart';
import '../../auth_and_group/providers/trip_providers.dart';
import '../../auth_and_group/repository/auth_repository.dart';
import '../models/checklist_item.dart';
import '../providers/checklist_providers.dart';
import '../utils/checklist_reminder_helper.dart';

/// Tab 1 — Chuẩn bị (Module 1: Mục tiêu chuyến đi & Checklist đa tầng).
class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key, this.tripId});

  final String? tripId;

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  int _tabIndex = 0; // 0: Việc theo mốc | 1: Hành lý & Đồ chung
  final _picker = ImagePicker();

  String _resolveTripId(WidgetRef ref) {
    return widget.tripId ?? ref.watch(currentTripIdProvider) ?? 'demo-trip';
  }

  Future<void> _showTemplatesSheet(TripModel trip) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChecklistTemplatesSheet(trip: trip),
    );
  }

  Future<void> _showAddItemSheet(
    String tripId,
    List<TripMember> members,
    int nextSortOrder,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddChecklistItemSheet(
        tripId: tripId,
        members: members,
        initialPhase:
            _tabIndex == 1 ? ChecklistPhase.packing : ChecklistPhase.before14d,
        nextSortOrder: nextSortOrder,
      ),
    );
  }

  Future<void> _pickAndUploadProof(ChecklistItem item) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Xác thực: ${item.title}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              AppInsetCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_camera, color: AppColors.primary),
                      title: const Text('Chụp ảnh bằng Camera'),
                      onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
                    ),
                    const Divider(indent: 56),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                      title: const Text('Chọn ảnh từ Thư viện'),
                      onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      final updated = await ref
          .read(checklistControllerProvider.notifier)
          .attachProofPhoto(item: item, imageBytes: bytes);
      if (!mounted) return;

      final ctrlState = ref.read(checklistControllerProvider);
      if (ctrlState.hasError || updated == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tải được ảnh: ${ctrlState.error}'),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đính kèm ảnh xác nhận: ${item.title}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở máy ảnh/thư viện: $e')),
      );
    }
  }

  Future<void> _showItemOptions(
    ChecklistItem item,
    List<TripMember> members,
  ) async {
    final currentUser = ref.read(authStateProvider).asData?.value ??
        ref.read(authRepositoryProvider).currentUser;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              AppInsetCard(
                child: Column(
                  children: [
                    if (members.isEmpty && currentUser != null)
                      ListTile(
                        leading: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
                        title: Text('Nhận việc (${currentUser.displayName})'),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          ref
                              .read(checklistControllerProvider.notifier)
                              .assignMember(
                                item: item,
                                assigneeId: currentUser.uid,
                                assigneeName: currentUser.displayName,
                              );
                        },
                      ),
                    ...members.map(
                      (m) => ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            m.initials,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text('Phân công: ${m.displayName}'),
                        trailing: item.assigneeId == m.userId
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          ref
                              .read(checklistControllerProvider.notifier)
                              .assignMember(
                                item: item,
                                assigneeId: m.userId,
                                assigneeName: m.displayName,
                              );
                        },
                      ),
                    ),
                    if (item.assigneeId != null)
                      ListTile(
                        leading: const Icon(Icons.person_off_outlined),
                        title: const Text('Bỏ phân công'),
                        onTap: () {
                          Navigator.pop(sheetCtx);
                          ref
                              .read(checklistControllerProvider.notifier)
                              .assignMember(item: item);
                        },
                      ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text(
                        'Xóa đầu việc',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        Navigator.pop(sheetCtx);
                        await ref
                            .read(checklistControllerProvider.notifier)
                            .deleteItem(item);
                      },
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

  void _showProofDialog(ChecklistItem item) {
    if (!item.hasProofPhoto) return;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: Image.network(
                item.proofImageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined, size: 42),
                      SizedBox(height: 8),
                      Text('Không tải được ảnh minh chứng.'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TripModel _fallbackTrip(String tripId) {
    final now = DateTime.now();
    return TripModel(
      id: tripId,
      title: 'Đà Lạt 4N3Đ',
      destination: 'Đà Lạt',
      startDate: now.add(const Duration(days: 14)),
      endDate: now.add(const Duration(days: 17)),
      hostId: 'demo-host-an',
      inviteCode: 'TB8K4M',
      targetBudget: 8450000,
      totalSavedAmount: 5500000,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripId = _resolveTripId(ref);
    ref.listen(tripChecklistProvider(tripId), (_, next) {
      final list = next.asData?.value;
      if (list != null) {
        ref.read(localNotificationServiceProvider).syncChecklistReminders(list);
      }
    });
    final trip = ref.watch(currentTripProvider).asData?.value ?? _fallbackTrip(tripId);
    final members = ref.watch(currentTripMembersProvider).asData?.value ?? const <TripMember>[];
    final checklistAsync = ref.watch(tripChecklistProvider(tripId));
    final items = checklistAsync.asData?.value ?? const <ChecklistItem>[];
    final readiness = ChecklistReminderHelper.computeReadiness(items);
    final reminderMessage = ChecklistReminderHelper.buildReminderMessage(readiness);
    final fundProgress = trip.fundProgress;
    final daysLeft = trip.daysUntilStart();
    final countdownText = daysLeft >= 0 ? 'Còn $daysLeft ngày' : 'Đang / đã đi';

    final grouped = _tabIndex == 0
        ? ChecklistReminderHelper.groupTimelineByPhase(items)
        : ChecklistReminderHelper.groupPackingByScope(items);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => context.go('/trips'),
          icon: const Icon(Icons.chevron_left, color: AppColors.onPrimaryContainer),
          label: const Text(
            'Chuyến đi',
            style: TextStyle(color: AppColors.onPrimaryContainer),
          ),
        ),
        title: Text(trip.title),
        actions: [
          IconButton(
            tooltip: 'Thành viên & Hồ sơ',
            icon: const Icon(Icons.group_outlined, color: AppColors.primary),
            onPressed: () => context.push('/trip/members'),
          ),
          IconButton(
            key: const Key('checklist_templates_button'),
            tooltip: 'Thư viện mẫu',
            icon: const Icon(Icons.auto_awesome_outlined, color: AppColors.primary),
            onPressed: () => _showTemplatesSheet(trip),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('checklist_add_fab'),
        heroTag: 'checklist_fab',
        onPressed: () => _showAddItemSheet(tripId, members, items.length),
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: checklistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Không tải được checklist: $err')),
        data: (_) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            // Thẻ Countdown & 2 vòng tròn tiến độ sẵn sàng trước giờ G
            AppInsetCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đếm ngược khởi hành',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              countdownText,
                              key: const Key('checklist_countdown_text'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: AppStatusBadge(
                          label: AppFormatters.formatDateRange(
                            trip.startDate,
                            trip.endDate,
                          ),
                          tone: AppBadgeTone.primary,
                          icon: Icons.event,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ReadinessRingTile(
                          title: 'Quỹ MoMo',
                          percent: fundProgress,
                          color: AppColors.momo,
                          subtitle: '${(fundProgress * 100).round()}% mục tiêu',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReadinessRingTile(
                          title: 'Chuẩn bị',
                          percentKey: const Key('checklist_readiness_percent'),
                          percent: readiness.progress,
                          color: AppColors.mint,
                          subtitle:
                              '${readiness.completedCount}/${readiness.totalCount} đầu việc',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (reminderMessage != null) ...[
              const SizedBox(height: 12),
              _DueReminderBanner(
                message: reminderMessage,
                hasOverdue: readiness.overdueItems.isNotEmpty,
              ),
            ],
            const SizedBox(height: 16),

            // Segmented Control: Việc theo mốc | Hành lý & Đồ chung
            AppSegmentedControl(
              segments: const ['Việc theo mốc', 'Hành lý & Đồ chung'],
              selectedIndex: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
            const SizedBox(height: 20),

            if (grouped.isEmpty)
              AppInsetCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.checklist_outlined,
                      size: 38,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chưa có đầu việc trong mục này',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hãy thêm việc mới hoặc chọn Bộ mẫu thông minh ở góc trên bên phải.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => _showTemplatesSheet(trip),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: const Text('Áp dụng Bộ mẫu'),
                    ),
                  ],
                ),
              )
            else
              ...grouped.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionHeader(title: entry.key),
                      AppInsetCard(
                        child: Column(
                          children: List.generate(entry.value.length, (idx) {
                            final item = entry.value[idx];
                            return Column(
                              children: [
                                _ChecklistItemRow(
                                  item: item,
                                  onToggle: () => ref
                                      .read(checklistControllerProvider.notifier)
                                      .toggleItem(item),
                                  onCameraTap: () => _pickAndUploadProof(item),
                                  onProofTap: () => _showProofDialog(item),
                                  onAssignTap: () =>
                                      _showItemOptions(item, members),
                                ),
                                if (idx < entry.value.length - 1)
                                  const Divider(indent: 50),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DueReminderBanner extends StatelessWidget {
  const _DueReminderBanner({
    required this.message,
    required this.hasOverdue,
  });

  final String message;
  final bool hasOverdue;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        hasOverdue ? const Color(0xFFFFEBEE) : AppColors.amberContainer;
    final fgColor =
        hasOverdue ? const Color(0xFFB71C1C) : const Color(0xFF8A5300);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            hasOverdue ? Icons.warning_amber_rounded : Icons.notifications_active_outlined,
            color: fgColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItemRow extends StatelessWidget {
  const _ChecklistItemRow({
    required this.item,
    required this.onToggle,
    required this.onCameraTap,
    required this.onProofTap,
    required this.onAssignTap,
  });

  final ChecklistItem item;
  final VoidCallback onToggle;
  final VoidCallback onCameraTap;
  final VoidCallback onProofTap;
  final VoidCallback onAssignTap;

  @override
  Widget build(BuildContext context) {
    final overdue = item.isOverdue();
    final dueSoon = item.isDueSoon();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            key: Key('checklist_toggle_${item.id}'),
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isCompleted
                    ? AppColors.mintContainer
                    : Colors.transparent,
                border: Border.all(
                  color: item.isCompleted ? AppColors.mint : AppColors.outline,
                  width: 2,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 15,
                      color: AppColors.onMintContainer,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    decoration:
                        item.isCompleted ? TextDecoration.lineThrough : null,
                    color: item.isCompleted
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                  ),
                ),
                if (item.dueDate != null && !item.isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Hạn: ${AppFormatters.formatDate(item.dueDate!)}${overdue ? ' • Quá hạn' : (dueSoon ? ' • Sắp đến hạn' : '')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            (overdue || dueSoon) ? FontWeight.w600 : FontWeight.w400,
                        color: overdue
                            ? const Color(0xFFB71C1C)
                            : (dueSoon
                                ? const Color(0xFF8A5300)
                                : AppColors.onSurfaceVariant),
                      ),
                    ),
                  ),
                if (item.hasProofPhoto)
                  GestureDetector(
                    onTap: onProofTap,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Icon(Icons.verified, size: 13, color: AppColors.mint),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Đã chụp ảnh xác thực • Xem',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.onMintContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Chụp ảnh xác nhận hoàn thành',
            icon: Icon(
              item.hasProofPhoto
                  ? Icons.photo_camera
                  : Icons.photo_camera_outlined,
              size: 20,
              color:
                  item.hasProofPhoto ? AppColors.mint : AppColors.onSurfaceVariant,
            ),
            onPressed: onCameraTap,
          ),
          InkWell(
            onTap: onAssignTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                item.assigneeName ?? 'Nhận việc',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: item.assigneeName != null
                      ? FontWeight.w500
                      : FontWeight.w600,
                  color: item.assigneeName != null
                      ? AppColors.onSurfaceVariant
                      : AppColors.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTemplatesSheet extends ConsumerWidget {
  const _ChecklistTemplatesSheet({required this.trip});

  final TripModel trip;

  IconData _iconForTripType(String tripType) {
    switch (tripType) {
      case 'beach':
        return Icons.beach_access;
      case 'trekking':
        return Icons.terrain;
      case 'motorbike':
        return Icons.two_wheeler;
      default:
        return Icons.backpack_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(checklistTemplatesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thư viện Mẫu Checklist (Smart Templates)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            templatesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Lỗi tải mẫu: $err'),
              data: (templates) => AppInsetCard(
                child: Column(
                  children: List.generate(templates.length, (idx) {
                    final tpl = templates[idx];
                    final isRecommended =
                        trip.tripType != TripType.other &&
                        tpl.tripType == trip.tripType.name;
                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            _iconForTripType(tpl.tripType),
                            color: AppColors.primary,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tpl.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (isRecommended) ...[
                                const SizedBox(width: 6),
                                const AppStatusBadge(
                                  label: 'Gợi ý',
                                  tone: AppBadgeTone.mint,
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            tpl.subtitle,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.outline,
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            final count = await ref
                                .read(checklistControllerProvider.notifier)
                                .applyTemplate(trip: trip, template: tpl);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  count > 0
                                      ? 'Đã thêm $count đầu việc từ mẫu "${tpl.name}".'
                                      : 'Các đầu việc của mẫu này đều đã có sẵn.',
                                ),
                              ),
                            );
                          },
                        ),
                        if (idx < templates.length - 1)
                          const Divider(indent: 56),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChecklistItemSheet extends ConsumerStatefulWidget {
  const _AddChecklistItemSheet({
    required this.tripId,
    required this.members,
    required this.initialPhase,
    required this.nextSortOrder,
  });

  final String tripId;
  final List<TripMember> members;
  final ChecklistPhase initialPhase;
  final int nextSortOrder;

  @override
  ConsumerState<_AddChecklistItemSheet> createState() =>
      _AddChecklistItemSheetState();
}

class _AddChecklistItemSheetState extends ConsumerState<_AddChecklistItemSheet> {
  final _titleCtrl = TextEditingController();
  late ChecklistPhase _phase;
  ChecklistScope _scope = ChecklistScope.group;
  DateTime? _dueDate;
  TripMember? _assignee;

  @override
  void initState() {
    super.initState();
    _phase = widget.initialPhase;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung đầu việc.')),
      );
      return;
    }

    final created = await ref.read(checklistControllerProvider.notifier).addItem(
          tripId: widget.tripId,
          title: title,
          phase: _phase,
          scope: _scope,
          assigneeId: _assignee?.userId,
          assigneeName: _assignee?.displayName,
          dueDate: _dueDate,
          sortOrder: widget.nextSortOrder,
        );
    if (!mounted) return;
    if (created != null) {
      Navigator.pop(context);
    } else {
      final err = ref.read(checklistControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thêm được việc: $err')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(checklistControllerProvider).isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Thêm đầu việc chuẩn bị',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('checklist_add_title_field'),
            controller: _titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Tên đầu việc / vật dụng',
              hintText: 'VD: Đặt vé xe giường nằm khứ hồi',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ChecklistPhase>(
            initialValue: _phase,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Giai đoạn / Nhóm',
              border: OutlineInputBorder(),
            ),
            items: ChecklistPhase.values
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(
                      p.shortLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _phase = val);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ChecklistScope>(
                  initialValue: _scope,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Phạm vi',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ChecklistScope.group,
                      child: Text(
                        'Việc chung nhóm',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: ChecklistScope.personal,
                      child: Text(
                        'Cá nhân',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _scope = val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(
                    _dueDate == null
                        ? 'Chọn hạn chót'
                        : AppFormatters.formatDate(_dueDate!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ),
            ],
          ),
          if (widget.members.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<TripMember?>(
              initialValue: _assignee,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Phân công cho (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<TripMember?>(
                  value: null,
                  child: Text('Chưa phân công'),
                ),
                ...widget.members.map(
                  (m) => DropdownMenuItem<TripMember?>(
                    value: m,
                    child: Text(
                      m.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _assignee = val),
            ),
          ],
          const SizedBox(height: 16),
          AppPrimaryButton(
            key: const Key('checklist_add_submit_button'),
            label: isSaving ? 'Đang lưu...' : 'Thêm đầu việc',
            onPressed: isSaving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _ReadinessRingTile extends StatelessWidget {
  const _ReadinessRingTile({
    required this.title,
    required this.percent,
    required this.color,
    required this.subtitle,
    this.percentKey,
  });

  final String title;
  final double percent;
  final Color color;
  final String subtitle;
  final Key? percentKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariantSoft),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 4.5,
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
                Center(
                  child: Text(
                    '${(percent * 100).round()}%',
                    key: percentKey,
                    style: AppTheme.monoAmount(
                      fontSize: 11,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
