import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../models/place_plan.dart';
import '../providers/itinerary_providers.dart';
import '../utils/schedule_conflict_helper.dart';
import 'add_activity_screen.dart';
import 'route_map_screen.dart';

class ItineraryScreen extends ConsumerWidget {
  final String tripId;
  final int dayCount;
  final String? destinationName;
  final double? destinationLat;
  final double? destinationLng;
  const ItineraryScreen({
    super.key,
    required this.tripId,
    this.dayCount = 3,
    this.destinationName,
    this.destinationLat,
    this.destinationLng,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider(tripId));
    final itinerary = ref.watch(itineraryProvider(tripId));
    final plans = itinerary.forDay(selectedDay);
    final conflicts = itinerary.conflicts(selectedDay);
    final notifier = ref.read(itineraryProvider(tripId).notifier);
    final hasGoRouter = GoRouter.maybeOf(context) != null;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: hasGoRouter ? 110 : null,
        leading: hasGoRouter
            ? TextButton.icon(
                onPressed: () => context.go('/trips'),
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.onPrimaryContainer,
                ),
                label: const Text(
                  'Chuyến đi',
                  style: TextStyle(color: AppColors.onPrimaryContainer),
                ),
              )
            : null,
        title: const Text('Lịch trình Travel Buddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Bản đồ',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RouteMapScreen(
                  tripId: tripId,
                  destinationName: destinationName,
                  initialLat: destinationLat,
                  initialLng: destinationLng,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dayCount,
              itemBuilder: (_, i) {
                final day = i + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: ChoiceChip(
                    label: Text('Ngày $day'),
                    selected: day == selectedDay,
                    onSelected: (_) =>
                        ref.read(selectedDayProvider(tripId).notifier).state =
                            day,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ngày $selectedDay: ${formatVnd(itinerary.dayCost(selectedDay))}',
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
              color: Color(0xfffff3cd),
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: Colors.orange),
                title: Text('Lịch trình có giờ bị trùng'),
                subtitle: Text(
                  'Các thẻ màu đỏ cần được điều chỉnh để chuyến đi thuận lợi hơn.',
                ),
              ),
            ),
          Expanded(
            child: itinerary.loading && itinerary.plans.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : plans.isEmpty
                ? const Center(
                    child: Text('Chưa có hoạt động nào trong ngày này.'),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: plans.length,
                    onReorder: (oldIndex, newIndex) =>
                        notifier.reorder(selectedDay, oldIndex, newIndex),
                    itemBuilder: (_, index) {
                      final plan = plans[index];
                      final conflict = conflicts.contains(plan.id);
                      return Card(
                        key: ValueKey(plan.id),
                        color: conflict ? const Color(0xffffebee) : null,
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(plan.placeName),
                          subtitle: Text(
                            '${formatTime(plan.startTime)} – ${formatTime(plan.endTime)} • ${_category(plan.category)}\n${plan.address}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit')
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddActivityScreen(
                                      tripId: tripId,
                                      initialPlan: plan,
                                      dayCount: dayCount,
                                      defaultLat: destinationLat,
                                      defaultLon: destinationLng,
                                    ),
                                  ),
                                );
                              if (value == 'delete')
                                await notifier.delete(plan);
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('itinerary_add_fab'),
        heroTag: 'itinerary_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddActivityScreen(
              tripId: tripId,
              dayCount: dayCount,
              defaultLat: destinationLat,
              defaultLon: destinationLng,
            ),
          ),
        ),
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
