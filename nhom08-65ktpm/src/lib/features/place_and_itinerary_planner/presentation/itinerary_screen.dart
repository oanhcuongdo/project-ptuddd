import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_skeleton_loader.dart';
import '../../../core/widgets/trip_detail_app_bar.dart';
import '../../auth_and_group/presentation/widgets/trip_members_sheet.dart';
import '../models/place_plan.dart';
import '../providers/itinerary_providers.dart';
import '../utils/schedule_conflict_helper.dart';
import 'add_activity_screen.dart';
import 'route_map_screen.dart';

class ItineraryScreen extends ConsumerWidget {
  final String tripId;
  final int dayCount;
  final DateTime? startDate;
  final String? destinationName;
  final double? destinationLat;
  final double? destinationLng;

  const ItineraryScreen({
    super.key,
    required this.tripId,
    this.dayCount = 3,
    this.startDate,
    this.destinationName,
    this.destinationLat,
    this.destinationLng,
  });

  String _dayChipLabel(int day) {
    if (startDate == null) return 'Ngày $day';
    final date = startDate!.add(Duration(days: day - 1));
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return 'Ngày $day · $dd/$mm';
  }

  Future<void> _openAddActivity(BuildContext context, {PlacePlan? plan}) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddActivityScreen(
            tripId: tripId,
            initialPlan: plan,
            dayCount: dayCount,
            defaultLat: destinationLat,
            defaultLon: destinationLng,
            destinationName: destinationName,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở form thêm địa điểm: $e')),
      );
    }
  }

  Future<void> _openRouteMap(BuildContext context) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RouteMapScreen(
            tripId: tripId,
            destinationName: destinationName,
            initialLat: destinationLat,
            initialLng: destinationLng,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở bản đồ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider(tripId));
    final itinerary = ref.watch(itineraryProvider(tripId));
    final plans = itinerary.forDay(selectedDay);
    final conflicts = itinerary.conflicts(selectedDay);
    final notifier = ref.read(itineraryProvider(tripId).notifier);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      appBar: TripDetailAppBar(
        title: destinationName?.trim().isNotEmpty == true
            ? 'Lịch trình · ${destinationName!.trim()}'
            : 'Lịch trình Travel Buddy',
        onMembersPressed: () => TripMembersSheet.show(context),
        extraActions: [
          IconButton(
            icon: Icon(Icons.map_outlined, color: primaryColor),
            tooltip: 'Bản đồ & check-in',
            onPressed: () => _openRouteMap(context),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: dayCount,
              itemBuilder: (_, i) {
                final day = i + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(_dayChipLabel(day)),
                    selected: day == selectedDay,
                    onSelected: (_) {
                      HapticFeedback.lightImpact();
                      ref.read(selectedDayProvider(tripId).notifier).state = day;
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ngày $selectedDay: ${formatVnd(itinerary.dayCost(selectedDay))}',
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
                Text(
                  'Toàn chuyến: ${formatVnd(itinerary.tripCost)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (conflicts.isNotEmpty)
            const Card(
              key: Key('itinerary_conflict_banner'),
              margin: EdgeInsets.all(12),
              color: AppColors.secondaryContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: AppColors.secondary),
                title: Text('Lịch trình có giờ bị trùng'),
                subtitle: Text(
                  'Các thẻ đánh dấu đỏ cần được điều chỉnh để chuyến đi thuận lợi hơn.',
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(itineraryProvider(tripId));
                await Future<void>.delayed(const Duration(milliseconds: 250));
              },
              child: itinerary.loading && itinerary.plans.isEmpty
                  ? const AppSkeletonLoader()
                  : plans.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        AppEmptyState(
                          icon: Icons.place_outlined,
                          title: 'Chưa có hoạt động trong ngày $selectedDay',
                          subtitle:
                              'Thêm điểm tham quan, ăn uống hoặc mở bản đồ để khám phá quanh ${destinationName ?? 'điểm đến'}.',
                          actionLabel: 'Thêm địa điểm',
                          onAction: () => _openAddActivity(context),
                        ),
                      ],
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                      itemCount: plans.length,
                      onReorderItem: (oldIndex, newIndex) {
                        HapticFeedback.lightImpact();
                        notifier.reorderAdjusted(selectedDay, oldIndex, newIndex);
                      },
                      itemBuilder: (_, index) {
                        final plan = plans[index];
                        final conflict = conflicts.contains(plan.id);
                        return Card(
                          key: ValueKey(plan.id),
                          color: conflict ? AppColors.errorContainer : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimaryContainer,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(plan.placeName),
                            subtitle: Text(
                              '${formatTime(plan.startTime)} – ${formatTime(plan.endTime)} • ${_category(plan.category)}\n${plan.address}',
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await _openAddActivity(context, plan: plan);
                                } else if (value == 'delete') {
                                  try {
                                    await notifier.delete(plan);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Không xóa được: $e')),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Xóa'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('itinerary_add_fab'),
        heroTag: 'itinerary_fab',
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        onPressed: () {
          HapticFeedback.lightImpact();
          _openAddActivity(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm địa điểm'),
      ),
    );
  }

  String _category(PlaceCategory c) => switch (c) {
    PlaceCategory.attraction => 'Tham quan',
    PlaceCategory.food => 'Ăn uống',
    PlaceCategory.hotel => 'Khách sạn',
  };
}
