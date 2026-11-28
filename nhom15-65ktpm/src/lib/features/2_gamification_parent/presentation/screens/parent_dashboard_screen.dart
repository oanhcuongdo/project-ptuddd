import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/services/parent_dashboard_statistics_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/attempt_log.dart';
import '../../../../shared/entities/badge_item.dart';
import '../../../../shared/entities/child_profile.dart';
import '../../../../shared/widgets/kid_badge_card.dart';
import '../widgets/parental_gate_dialog.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen._();

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class ParentDashboardRoute {
  const ParentDashboardRoute._();

  static Future<void> open(BuildContext context) async {
    final isAuthenticated = await ParentalGateDialog.authenticate(context);
    if (!isAuthenticated || !context.mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const ParentDashboardScreen._(),
      ),
    );
  }
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final StorageService _storageService = sl<StorageService>();
  ChildProfile? _profile;
  List<AttemptLog> _allLogs = [];
  ReminderSettings _reminderSettings = const ReminderSettings();
  String _logFilter = 'all'; // 'all', 'correct', 'incorrect'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _storageService.getChildProfile();
    final logs = await _storageService.getRecentLogs();
    final reminder = await ReminderService.getSettings();

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _allLogs = logs;
      _reminderSettings = reminder;
      _isLoading = false;
    });
  }

  Future<void> _toggleReminder(bool enabled) async {
    await ReminderService.saveSettings(
      enabled: enabled,
      hour: _reminderSettings.hour,
      minute: _reminderSettings.minute,
    );
    setState(() {
      _reminderSettings = ReminderSettings(
        enabled: enabled,
        hour: _reminderSettings.hour,
        minute: _reminderSettings.minute,
      );
    });
  }

  List<AttemptLog> get _filteredLogs {
    final filteredLogs = switch (_logFilter) {
      'correct' => _allLogs.where((log) => log.isCorrect),
      'incorrect' => _allLogs.where((log) => !log.isCorrect),
      _ => _allLogs,
    };
    return ParentDashboardStatisticsService.newestFirst(
      filteredLogs.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final statistics = ParentDashboardStatisticsService.calculate(_allLogs);
    final totalAttempts = statistics.totalAttempts;
    final correctAttempts = statistics.correctAttempts;
    final accuracyPercent = statistics.accuracyPercent;
    final avgTimeMs = statistics.averageResponseTimeMs;
    final avgTimeSeconds =
        avgTimeMs == null ? '—' : '${(avgTimeMs / 1000).toStringAsFixed(1)}s';
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 400 ? 12.0 : 24.0;
    final metricColumns = width >= 1000
        ? 4
        : width >= 600
            ? 2
            : 1;
    final badgeColumns = width >= 1000
        ? 4
        : width >= 600
            ? 3
            : 2;

    return Theme(
      data: AppTheme.parentTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bảng điều khiển phụ huynh'),
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Tổng quan tiến độ học tập'),
                    const SizedBox(height: 12),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: metricColumns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: metricColumns == 1
                            ? 1.9
                            : metricColumns == 4
                                ? 1.8
                                : 2.1,
                      ),
                      children: [
                        _buildMetricCard(
                          title: 'Câu hỏi đã hoàn thành',
                          value: '$totalAttempts',
                          subtitle: 'Trong 7 ngày qua, tối đa 50 lượt lưu',
                          icon: Icons.assignment_turned_in_outlined,
                          color: AppColors.primaryText,
                        ),
                        _buildMetricCard(
                          title: 'Tỷ lệ trả lời chính xác',
                          value: accuracyPercent == null
                              ? '—'
                              : '$accuracyPercent%',
                          subtitle: totalAttempts == 0
                              ? 'Chưa có dữ liệu'
                              : '$correctAttempts / $totalAttempts câu đúng',
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                        _buildMetricCard(
                          title: 'Thời gian suy nghĩ trung bình',
                          value: avgTimeSeconds,
                          subtitle: avgTimeMs == null
                              ? 'Chưa có dữ liệu'
                              : 'Trung bình $avgTimeMs ms',
                          icon: Icons.timer_outlined,
                          color: AppColors.primaryText,
                        ),
                        _buildMetricCard(
                          title: 'Chuỗi học hiện tại',
                          value: '${_profile?.streakCount ?? 0} ngày',
                          subtitle:
                              'Kỷ lục: ${_profile?.longestStreak ?? 0} ngày',
                          icon: Icons.local_fire_department_outlined,
                          color: AppColors.primaryText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle(
                        context, 'Thống kê theo ngày trong tuần'),
                    const SizedBox(height: 12),
                    _buildBarChartContainer(statistics),
                    const SizedBox(height: 24),
                    _buildReminderCard(),
                    const SizedBox(height: 24),
                    _buildBadgesSection(badgeColumns),
                    const SizedBox(height: 24),
                    _buildDetailedHistorySection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = _profile;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.cardBg,
            child: Icon(
              Icons.person_outline_rounded,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name.trim().isNotEmpty == true
                      ? profile!.name
                      : 'Hồ sơ học tập',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile == null
                      ? 'Chưa có thông tin hồ sơ'
                      : '${profile.age} tuổi • Cấp độ ${profile.currentLevel}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildProfileTag(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Chuỗi: ${profile?.streakCount ?? 0} ngày',
                    ),
                    _buildProfileTag(
                      icon: Icons.stars_rounded,
                      label: 'Điểm: ${profile?.totalPoints ?? 0}',
                    ),
                    _buildProfileTag(
                      icon: Icons.emoji_events_outlined,
                      label:
                          '${profile?.unlockedBadgeIds.length ?? 0} huy hiệu',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTag({
    required IconData icon,
    required String label,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.primaryText),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartContainer(ParentDashboardStatistics statistics) {
    const weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final maximumAttempts = statistics.attemptsByWeekday.fold<int>(
      0,
      (maximum, count) => count > maximum ? count : maximum,
    );
    final chartMaximum = maximumAttempts == 0
        ? 1.0
        : (maximumAttempts + 1).toDouble();
    final gridInterval = maximumAttempts < 3
        ? 1.0
        : (maximumAttempts / 3).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.parentCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            statistics.hasData
                ? 'Số lượt làm trong 7 ngày gần nhất'
                : 'Chưa có dữ liệu trong 7 ngày gần nhất',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Biểu đồ số câu hỏi đã làm trong 7 ngày gần nhất',
            child: SizedBox(
              height: 190,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: chartMaximum,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${weekdayLabels[group.x]}: ${rod.toY.round()} câu',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= weekdayLabels.length) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${statistics.attemptsByWeekday[index]}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.chartAxisLabel,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Text(
                                  weekdayLabels[index],
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.chartAxisLabel,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: gridInterval,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColors.chartGrid,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(weekdayLabels.length, (index) {
                    final count = statistics.attemptsByWeekday[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: AppColors.chartPrimary,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                duration: const Duration(milliseconds: 250),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_on_rounded,
                color: AppColors.accentOrange, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch Nhắc Học Cố Định 19:00',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 3),
                Text(
                  _reminderSettings.statusText,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Switch(
            value: _reminderSettings.enabled,
            activeColor: AppColors.accentOrange,
            onChanged: _toggleReminder,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(int columns) {
    final unlockedIds = Set<String>.from(_profile?.unlockedBadgeIds ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildSectionTitle(context, 'Bộ sưu tập huy hiệu'),
            Text(
              '${unlockedIds.length} / ${BadgeDefinitions.allBadges.length} đã mở',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: BadgeDefinitions.allBadges.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns >= 4 ? 1.15 : 0.95,
          ),
          itemBuilder: (context, index) {
            final badge = BadgeDefinitions.allBadges[index];
            final isUnlocked = unlockedIds.contains(badge.id);

            return KidBadgeCard(
              badge: badge,
              isUnlocked: isUnlocked,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailedHistorySection() {
    final logs = _filteredLogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Lịch sử làm bài chi tiết'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildFilterChip('Tất cả', 'all'),
            _buildFilterChip('Đúng', 'correct'),
            _buildFilterChip('Cần ôn', 'incorrect'),
          ],
        ),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                'Chưa có lịch sử làm bài theo bộ lọc này.',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              final isCorrect = log.isCorrect;
              final statusColor =
                  isCorrect ? AppColors.success : AppColors.error;
              final timestamp = DateTime.tryParse(log.timestamp)?.toLocal();
              final timestampLabel = timestamp == null
                  ? 'Thời điểm không có sẵn'
                  : '${timestamp.day.toString().padLeft(2, '0')}/'
                      '${timestamp.month.toString().padLeft(2, '0')}/'
                      '${timestamp.year} '
                      '${timestamp.hour.toString().padLeft(2, '0')}:'
                      '${timestamp.minute.toString().padLeft(2, '0')}';
              final question = log.questionText.trim().isNotEmpty
                  ? log.questionText.trim()
                  : 'Bài tập ID: ${log.questionId}';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 760),
                                child: Text(
                                  question,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              _buildHistoryStatusChip(
                                isCorrect: isCorrect,
                                color: statusColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              _buildHistoryDetail(
                                icon: Icons.edit_outlined,
                                text: 'Câu trả lời: ${log.userAnswer}',
                              ),
                              _buildHistoryDetail(
                                icon: Icons.timer_outlined,
                                text: 'Thời gian: ${log.responseTimeMs} ms',
                              ),
                              _buildHistoryDetail(
                                icon: Icons.access_time_rounded,
                                text: timestampLabel,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildHistoryStatusChip({
    required bool isCorrect,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isCorrect ? 'Chính xác' : 'Chưa chính xác',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHistoryDetail({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textLight),
        const SizedBox(width: 5),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textLight,
              ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _logFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textDark,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.buttonPrimary,
      backgroundColor: AppColors.parentCardBg,
      side: BorderSide(
        color: isSelected ? AppColors.buttonPrimaryOutline : AppColors.outline,
      ),
      onSelected: (_) => setState(() => _logFilter = value),
    );
  }
}
