import '../models/checklist_item.dart';

class ReadinessStats {
  const ReadinessStats({
    required this.totalCount,
    required this.completedCount,
    required this.overdueItems,
    required this.dueSoonItems,
  });

  final int totalCount;
  final int completedCount;
  final List<ChecklistItem> overdueItems;
  final List<ChecklistItem> dueSoonItems;

  double get progress =>
      totalCount <= 0 ? 0.0 : (completedCount / totalCount).clamp(0.0, 1.0);

  int get percent => (progress * 100).round();

  int get urgentCount => overdueItems.length + dueSoonItems.length;

  bool get hasUrgentReminders => urgentCount > 0;
}

abstract final class ChecklistReminderHelper {
  static ReadinessStats computeReadiness(
    List<ChecklistItem> items, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final completed = items.where((item) => item.isCompleted).length;
    final overdue = items.where((item) => item.isOverdue(ref)).toList();
    final dueSoon = items.where((item) => item.isDueSoon(ref)).toList();

    return ReadinessStats(
      totalCount: items.length,
      completedCount: completed,
      overdueItems: overdue,
      dueSoonItems: dueSoon,
    );
  }

  static String? buildReminderMessage(ReadinessStats stats) {
    if (!stats.hasUrgentReminders) return null;
    if (stats.overdueItems.isNotEmpty && stats.dueSoonItems.isNotEmpty) {
      return 'Có ${stats.overdueItems.length} việc quá hạn và ${stats.dueSoonItems.length} việc sắp đến hạn trong 48h tới.';
    }
    if (stats.overdueItems.isNotEmpty) {
      return 'Có ${stats.overdueItems.length} việc chuẩn bị đã quá hạn: "${stats.overdueItems.first.title}".';
    }
    return 'Nhắc việc: ${stats.dueSoonItems.length} việc sắp đến hạn ("${stats.dueSoonItems.first.title}").';
  }

  static Map<String, List<ChecklistItem>> groupTimelineByPhase(
    List<ChecklistItem> items,
  ) {
    const order = [
      ChecklistPhase.before30d,
      ChecklistPhase.before14d,
      ChecklistPhase.before3d,
    ];
    final grouped = <String, List<ChecklistItem>>{};
    for (final phase in order) {
      final list = items.where((e) => e.phase == phase).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (list.isNotEmpty) {
        grouped[phase.label] = list;
      }
    }
    return grouped;
  }

  static Map<String, List<ChecklistItem>> groupPackingByScope(
    List<ChecklistItem> items,
  ) {
    final packing = items.where((e) => e.phase == ChecklistPhase.packing).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final grouped = <String, List<ChecklistItem>>{};
    final groupItems =
        packing.where((e) => e.scope == ChecklistScope.group).toList();
    final personalItems =
        packing.where((e) => e.scope == ChecklistScope.personal).toList();

    if (groupItems.isNotEmpty) {
      grouped['Đồ dùng chung của nhóm'] = groupItems;
    }
    if (personalItems.isNotEmpty) {
      grouped['Hành lý cá nhân của bạn'] = personalItems;
    }
    return grouped;
  }
}
