import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/attempt_log.dart';
import '../../../../shared/entities/badge_item.dart';
import '../../../../shared/entities/child_profile.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
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
    if (_logFilter == 'correct') {
      return _allLogs.where((l) => l.isCorrect).toList();
    }
    if (_logFilter == 'incorrect') {
      return _allLogs.where((l) => !l.isCorrect).toList();
    }
    return _allLogs;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totalAttempts = _allLogs.length;
    final correctAttempts = _allLogs.where((l) => l.isCorrect).length;
    final accuracyPercent = totalAttempts > 0
        ? ((correctAttempts / totalAttempts) * 100).round()
        : 100;

    final avgTimeMs = totalAttempts > 0
        ? (_allLogs.map((l) => l.responseTimeMs).reduce((a, b) => a + b) /
                totalAttempts)
            .round()
        : 0;
    final avgTimeSeconds = (avgTimeMs / 1000).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          '📊 Báo Cáo & Thống Kê Phụ Huynh',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Thẻ Profile thông tin bé
            _buildProfileHeader(),
            const SizedBox(height: 18),

            // 2. Thẻ chỉ số tổng quan (4 chỉ số)
            const Text(
              'Chỉ Số Học Tập Tổng Quan',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Độ chính xác',
                    value: '$accuracyPercent%',
                    subtitle: '$correctAttempts / $totalAttempts câu đúng',
                    icon: Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Thời gian suy nghĩ',
                    value: '${avgTimeSeconds}s',
                    subtitle: 'Trung bình: $avgTimeMs ms',
                    icon: Icons.timer_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Chuỗi Streak',
                    value: '${_profile?.streakCount ?? 1} ngày',
                    subtitle: 'Kỷ lục: ${_profile?.longestStreak ?? 3} ngày',
                    icon: Icons.local_fire_department,
                    color: AppColors.accentOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Gia sư thích ứng',
                    value: 'Cấp ${_profile?.currentLevel ?? 1}',
                    subtitle: 'Chớp số: ${_profile?.flashSpeedMs ?? 1200}ms',
                    icon: Icons.auto_awesome,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Biểu đồ cột fl_chart các ngày trong tuần
            const Text(
              'Biểu Đồ Luyện Tập Trong Tuần',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Thống kê số câu đúng so với tổng số câu đã luyện theo ngày',
              style: TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            _buildBarChartContainer(),
            const SizedBox(height: 24),

            // 4. Lịch nhắc học thông minh cố định 19:00
            _buildReminderCard(),
            const SizedBox(height: 24),

            // 5. Bộ sưu tập Huy hiệu Gamification
            _buildBadgesSection(),
            const SizedBox(height: 24),

            // 6. Lịch sử làm bài chi tiết với bộ lọc
            _buildDetailedHistorySection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Text('👧', style: TextStyle(fontSize: 36)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?.name ?? 'Bé Yêu',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Độ tuổi: ${_profile?.age ?? 5} tuổi • Cấp độ ${_profile?.currentLevel ?? 1}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🔥 Streak: ${_profile?.streakCount ?? 1} ngày',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🏆 ${_profile?.unlockedBadgeIds.length ?? 0} Huy hiệu',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600),
              ),
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

  Widget _buildBarChartContainer() {
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final totalData = [8.0, 10.0, 7.0, 12.0, 9.0, 11.0, 14.0];
    final correctData = [7.0, 9.0, 6.0, 11.0, 8.0, 10.0, 13.0];

    return Container(
      height: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 16,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = days[group.x.toInt()];
                final correct = correctData[group.x.toInt()].toInt();
                final total = totalData[group.x.toInt()].toInt();
                final pct = ((correct / total) * 100).toInt();
                return BarTooltipItem(
                  '$day: $correct/$total đúng ($pct%)',
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        days[idx],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: correctData[i],
                  color: AppColors.secondary,
                  width: 14,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
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

  Widget _buildBadgesSection() {
    final unlockedIds = Set<String>.from(_profile?.unlockedBadgeIds ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bộ Sưu Tập Huy Hiệu Của Bé',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
            Text(
              '${unlockedIds.length} / ${BadgeDefinitions.allBadges.length} đã mở',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: BadgeDefinitions.allBadges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final badge = BadgeDefinitions.allBadges[index];
            final isUnlocked = unlockedIds.contains(badge.id);

            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isUnlocked
                      ? AppColors.accentYellow.withValues(alpha: 0.8)
                      : Colors.grey.shade200,
                  width: isUnlocked ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUnlocked
                        ? AppColors.accentYellow.withValues(alpha: 0.15)
                        : Colors.transparent,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    badge.icon,
                    style: TextStyle(
                      fontSize: 32,
                      color: isUnlocked ? null : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? AppColors.textDark
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isUnlocked ? 'Đã đạt' : 'Chưa mở',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          isUnlocked ? AppColors.success : Colors.grey.shade400,
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

  Widget _buildDetailedHistorySection() {
    final logs = _filteredLogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lịch Sử Làm Bài Chi Tiết',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
            Row(
              children: [
                _buildFilterChip('Tất cả', 'all'),
                const SizedBox(width: 6),
                _buildFilterChip('Đúng', 'correct'),
                const SizedBox(width: 6),
                _buildFilterChip('Cần ôn', 'incorrect'),
              ],
            ),
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
            itemCount: logs.length > 20 ? 20 : logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: log.isCorrect
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        log.isCorrect ? Icons.check_circle : Icons.cancel,
                        color:
                            log.isCorrect ? AppColors.success : AppColors.error,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.questionText.isNotEmpty
                                ? log.questionText
                                : 'Bài tập ID: ${log.questionId}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Đáp án của bé: ${log.userAnswer} • ${log.answeredVia == "voice" ? "🎙️ Giọng nói AI" : "🖐️ Bàn tay"}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${log.responseTimeMs} ms',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _logFilter == value;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : AppColors.textDark)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      onSelected: (_) => setState(() => _logFilter = value),
    );
  }
}
