import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_inset_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../models/trip_model.dart';
import '../providers/auth_providers.dart';
import '../providers/trip_providers.dart';
import 'widgets/join_trip_qr_sheet.dart';

/// Màn hình Danh sách chuyến đi — đồng bộ realtime từ Firestore (`tripListProvider`).
class TripListScreen extends ConsumerStatefulWidget {
  const TripListScreen({super.key});

  @override
  ConsumerState<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends ConsumerState<TripListScreen> {
  int _selectedFilter = 0;
  String _searchQuery = '';
  final _filters = const ['Tất cả', 'Đang chuẩn bị', 'Sắp tới', 'Đã kết thúc'];

  List<TripModel> _applyFilters(List<TripModel> trips) {
    final query = _searchQuery.trim().toLowerCase();
    return trips.where((trip) {
      if (query.isNotEmpty) {
        final matchesTitle = trip.title.toLowerCase().contains(query);
        final matchesDest = trip.destination.toLowerCase().contains(query);
        if (!matchesTitle && !matchesDest) return false;
      }
      switch (_selectedFilter) {
        case 1:
          return trip.status == TripStatus.planning;
        case 2:
          return trip.status == TripStatus.ongoing ||
              (trip.status == TripStatus.planning && trip.daysUntilStart() >= 0);
        case 3:
          return trip.status == TripStatus.completed;
        default:
          return true;
      }
    }).toList();
  }

  void _openJoinQrSheet() {
    showModalBottomSheet<TripModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const JoinTripQrSheet(),
    );
  }

  void _openTrip(TripModel trip) {
    ref.read(selectedTripIdProvider.notifier).select(trip.id);
    context.go('/trip/checklist');
  }

  Future<void> _handleSignOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);
    final tripsAsync = ref.watch(tripListProvider);
    final user = userAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 140,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            onTap: _handleSignOut,
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    user?.initials ?? 'TB',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user?.displayName ?? 'Khách',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        title: const Text('Chuyến đi'),
        actions: [
          IconButton(
            key: const Key('trip_list_qr_button'),
            tooltip: 'Quét QR tham gia nhóm',
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            onPressed: _openJoinQrSheet,
          ),
          IconButton(
            key: const Key('trip_list_add_button'),
            tooltip: 'Tạo chuyến đi mới',
            icon: const Icon(Icons.add, color: AppColors.primary, size: 26),
            onPressed: () => context.push('/trips/create'),
          ),
          IconButton(
            key: const Key('trip_list_logout_button'),
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: AppColors.onSurfaceVariant, size: 21),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ô tìm kiếm
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
                hintText: 'Tìm chuyến đi, địa điểm...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final active = _selectedFilter == index;
                return ChoiceChip(
                  label: Text(_filters[index]),
                  selected: active,
                  onSelected: (_) => setState(() => _selectedFilter = index),
                  selectedColor: AppColors.primaryContainer,
                  backgroundColor: AppColors.surfaceContainer,
                  side: BorderSide(
                    color: active ? Colors.transparent : AppColors.outlineVariantSoft,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurfaceVariant,
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          tripsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => AppInsetCard(
              padding: const EdgeInsets.all(16),
              child: Text('Không tải được danh sách chuyến đi: $err'),
            ),
            data: (trips) {
              final filtered = _applyFilters(trips);
              if (filtered.isEmpty) {
                return AppInsetCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.luggage_outlined,
                        size: 40,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Chưa có chuyến đi nào',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Bấm dấu + để tạo chuyến đi mới hoặc quét mã QR để tham gia cùng bạn bè.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _openJoinQrSheet,
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: const Text('Quét QR'),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: () => context.push('/trips/create'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Tạo mới'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              final featured = filtered.first;
              final others = filtered.skip(1).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSectionHeader(title: 'Đang chuẩn bị'),
                  _FeaturedTripCard(
                    trip: featured,
                    onTap: () => _openTrip(featured),
                  ),
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const AppSectionHeader(title: 'Các chuyến đi khác'),
                    AppInsetCard(
                      child: Column(
                        children: List.generate(others.length, (index) {
                          final trip = others[index];
                          final daysLeft = trip.daysUntilStart();
                          final daysLabel = daysLeft >= 0
                              ? 'Còn $daysLeft ngày'
                              : 'Đã diễn ra';
                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.flight_takeoff,
                                    color: AppColors.primary,
                                  ),
                                ),
                                title: Text(
                                  trip.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${AppFormatters.formatDateRange(trip.startDate, trip.endDate)} • ${trip.memberIds.length} người • $daysLabel',
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.outline,
                                ),
                                onTap: () => _openTrip(trip),
                              ),
                              if (index < others.length - 1)
                                const Divider(indent: 72),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeaturedTripCard extends StatelessWidget {
  const _FeaturedTripCard({required this.trip, required this.onTap});

  final TripModel trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fundPercent = trip.fundProgress;
    final checklistPercent = trip.checklistProgress;
    final daysLeft = trip.daysUntilStart();
    final countdownText =
        daysLeft >= 0 ? 'Còn $daysLeft ngày' : 'Đang / đã đi';

    return GestureDetector(
      onTap: onTap,
      child: AppInsetCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                AppStatusBadge(
                  label: countdownText,
                  tone: AppBadgeTone.amber,
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${AppFormatters.formatDateRange(trip.startDate, trip.endDate)} • ${trip.memberIds.length} thành viên',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniProgressBox(
                    label: 'Quỹ MoMo',
                    valueText: '${(fundPercent * 100).round()}%',
                    progress: fundPercent,
                    color: AppColors.momo,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniProgressBox(
                    label: 'Checklist',
                    valueText: '${(checklistPercent * 100).round()}%',
                    progress: checklistPercent,
                    color: AppColors.mint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppStatusBadge(
                  label: 'Mã mời: ${trip.inviteCode}',
                  tone: AppBadgeTone.momo,
                  icon: Icons.qr_code_2,
                ),
                Text(
                  AppFormatters.formatVnd(trip.targetBudget),
                  style: AppTheme.monoAmount(
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniProgressBox extends StatelessWidget {
  const _MiniProgressBox({
    required this.label,
    required this.valueText,
    required this.progress,
    required this.color,
  });

  final String label;
  final String valueText;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outlineVariantSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(valueText, style: AppTheme.monoAmount(fontSize: 13, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
