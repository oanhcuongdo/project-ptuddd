import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../providers/sleep_provider.dart';
import '../../providers/settings_provider.dart';
import '../sleep_management/sleep_goal_screen.dart';
import '../sleep_management/sleep_diary_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onNavigateTab;
  final VoidCallback? onOpenDrawer;

  const HomeScreen({
    super.key,
    required this.onNavigateTab,
    this.onOpenDrawer,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _quoteIndex = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  final List<Map<String, String>> _sleepQuotes = const [
    {
      'quote': 'Giấc ngủ là chiếc máy làm sạch tối thượng cho não bộ và tái tạo năng lượng cho toàn cơ thể.',
      'author': 'GS. Matthew Walker (Tác giả cuốn "Tại sao chúng ta ngủ")',
    },
    {
      'quote': 'Một giấc chợp mắt Power Nap 15-20 phút có thể phục hồi tới 34% sự tỉnh táo và tập trung.',
      'author': 'Nghiên cứu giấc ngủ của NASA',
    },
    {
      'quote': 'Kỷ luật duy trì một khung giờ đi ngủ cố định quan trọng hơn cả tổng số giờ bạn nằm trên giường.',
      'author': 'Tổ chức Giấc ngủ Quốc tế (Sleep Foundation)',
    },
    {
      'quote': 'Kỹ thuật thở 4-7-8 giúp hệ thần kinh phó giao cảm đưa cơ thể vào trạng thái thư giãn chỉ sau 2 phút.',
      'author': 'TS. Andrew Weil (Đại học Harvard)',
    },
    {
      'quote': 'Tránh ánh sáng xanh từ màn hình điện thoại 30 phút trước khi ngủ kích thích sản sinh Melatonin tự nhiên.',
      'author': 'Viện Y học Giấc ngủ Hoa Kỳ (AASM)',
    },
  ];

  void _nextQuote() {
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % _sleepQuotes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sleepProv = context.watch<SleepProvider>();
    final settingsProv = context.watch<SettingsProvider>();
    final goal = sleepProv.goal;
    final latestRecord = sleepProv.latestRecord;
    final userName = settingsProv.user.name;

    return Scaffold(
      appBar: AppBar(
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu mở rộng',
                onPressed: widget.onOpenDrawer,
              )
            : null,
        title: const Text('DCSleep Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt & Tài khoản',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: sleepProv.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => sleepProv.loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Dynamic Real-time Greeting Header
                    _buildGreetingHeader(userName),
                    const SizedBox(height: 16),

                    // 2. Sleep Goal Card with Midnight Aurora Gradient
                    _buildGoalCard(context, goal),
                    const SizedBox(height: 16),

                    // 3. Discipline Progress Gauge Card
                    _buildDisciplineCard(
                      context,
                      sleepProv.complianceRate,
                      sleepProv.averageDurationHours,
                    ),
                    const SizedBox(height: 16),

                    // 4. Quick Action Shortcuts
                    _buildQuickActionButtons(context),
                    const SizedBox(height: 18),

                    // 5. Scientific Sleep Quote & Wisdom Card
                    _buildSleepQuoteCard(),
                    const SizedBox(height: 18),

                    // 6. Latest Sleep Record Summary
                    _buildLatestRecordCard(context, latestRecord),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accentIndigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Ghi nhật ký ngủ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SleepDiaryScreen()),
          );
        },
      ),
    );
  }

  // --- 1. Real-time Greeting Header ---
  Widget _buildGreetingHeader(String fullName) {
    final now = DateTime.now();
    final hour = now.hour;
    final shortName = fullName.split(' ').last;

    String greeting;
    String subtitle;
    IconData icon;
    Color iconColor;

    if (hour >= 5 && hour < 12) {
      greeting = 'Chào buổi sáng, $shortName! ☀️';
      subtitle = 'Đêm qua bạn ngủ thế nào? Hãy cập nhật nhật ký nhé.';
      icon = Icons.wb_sunny_rounded;
      iconColor = AppTheme.softAmber;
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Chào buổi chiều, $shortName! 🌤️';
      subtitle = 'Nạp lại năng lượng bằng một giấc chợp mắt Power Nap nhé.';
      icon = Icons.wb_twilight_rounded;
      iconColor = const Color(0xFFF97316);
    } else {
      greeting = 'Chào buổi tối, $shortName! 🌙';
      subtitle = 'Chuẩn bị không gian yên tĩnh và thư thái cho giấc ngủ sâu.';
      icon = Icons.nights_stay_rounded;
      iconColor = AppTheme.accentCyan;
    }

    final dateStr = 'Hôm nay, ngày ${TimeUtils.formatDate(now)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardNavy.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.accentCyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Sleep Goal Card with Aurora Gradient ---
  Widget _buildGoalCard(BuildContext context, dynamic goal) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1B4B), // Deep indigo
            Color(0xFF0F172A), // Midnight navy
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.accentIndigo.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentIndigo.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentIndigo.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bedtime_outlined,
                    color: AppTheme.accentCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kế Hoạch Giấc Ngủ Mục Tiêu',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Duy trì đều đặn để tạo đồng hồ sinh học',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SleepGoalScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 12, color: AppTheme.accentCyan),
                        SizedBox(width: 4),
                        Text('Sửa', style: TextStyle(fontSize: 11, color: AppTheme.accentCyan)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeColumn(
                  label: 'Giờ đi ngủ',
                  timeStr: TimeUtils.formatTime(
                    goal.bedtimeHour,
                    goal.bedtimeMinute,
                  ),
                  icon: Icons.nightlight_round,
                  color: AppTheme.accentCyan,
                ),
                Container(width: 1, height: 42, color: AppTheme.cardNavy),
                _buildTimeColumn(
                  label: 'Giờ thức dậy',
                  timeStr: TimeUtils.formatTime(goal.wakeHour, goal.wakeMinute),
                  icon: Icons.wb_sunny_outlined,
                  color: AppTheme.softAmber,
                ),
                Container(width: 1, height: 42, color: AppTheme.cardNavy),
                _buildTimeColumn(
                  label: 'Thời lượng',
                  timeStr: '${goal.targetDurationHours.toStringAsFixed(1)}h',
                  icon: Icons.timer_outlined,
                  color: AppTheme.softGreen,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNextSleepCountdownBanner(goal),
          ],
        ),
      ),
    );
  }

  Widget _buildNextSleepCountdownBanner(dynamic goal) {
    final now = DateTime.now();

    DateTime nextBedtime = DateTime(
      now.year,
      now.month,
      now.day,
      goal.bedtimeHour,
      goal.bedtimeMinute,
    );
    if (!nextBedtime.isAfter(now)) {
      nextBedtime = nextBedtime.add(const Duration(days: 1));
    }

    DateTime nextWake = DateTime(
      now.year,
      now.month,
      now.day,
      goal.wakeHour,
      goal.wakeMinute,
    );
    if (!nextWake.isAfter(now)) {
      nextWake = nextWake.add(const Duration(days: 1));
    }

    final diffBed = nextBedtime.difference(now);
    final diffWake = nextWake.difference(now);
    final isBedtimeNext = diffBed <= diffWake;
    final remaining = isBedtimeNext ? diffBed : diffWake;

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    final targetTimeStr = isBedtimeNext
        ? TimeUtils.formatTime(goal.bedtimeHour, goal.bedtimeMinute)
        : TimeUtils.formatTime(goal.wakeHour, goal.wakeMinute);

    final label = isBedtimeNext
        ? 'Còn $hours giờ $minutes phút nữa đến giờ đi ngủ ($targetTimeStr)'
        : 'Còn $hours giờ $minutes phút nữa đến giờ thức dậy ($targetTimeStr)';

    final countdownBadge =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final accentColor = isBedtimeNext ? AppTheme.accentCyan : AppTheme.softAmber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceNavy.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isBedtimeNext ? Icons.bedtime_rounded : Icons.alarm_rounded,
            color: accentColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              countdownBadge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: accentColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn({
    required String label,
    required String timeStr,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          timeStr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // --- 3. Discipline Progress Card ---
  Widget _buildDisciplineCard(
    BuildContext context,
    double rate,
    double avgHours,
  ) {
    String badgeText;
    Color badgeColor;

    if (rate >= 80) {
      badgeText = 'Xuất sắc 🏆';
      badgeColor = AppTheme.softGreen;
    } else if (rate >= 50) {
      badgeText = 'Khá tốt 📈';
      badgeColor = AppTheme.accentCyan;
    } else {
      badgeText = 'Cần cố gắng 🎯';
      badgeColor = AppTheme.softAmber;
    }

    return Card(
      color: AppTheme.surfaceNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.cardNavy.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: rate / 100.0,
                    strokeWidth: 6.5,
                    backgroundColor: AppTheme.cardNavy,
                    valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                  ),
                ),
                Text(
                  '${rate.round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chỉ số Kỷ luật Giấc ngủ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Thời lượng trung bình 7 ngày: ${TimeUtils.formatDuration(avgHours)}. Đạt mục tiêu ${rate.round()}% các ngày gần nhất.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. Quick Action Shortcuts ---
  Widget _buildQuickActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: AppTheme.surfaceNavy,
              side: BorderSide(color: AppTheme.accentCyan.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.flash_on, color: AppTheme.accentCyan, size: 20),
            label: const Text(
              'Power Nap (15-20p)',
              style: TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () => widget.onNavigateTab(2), // Tab Power Nap
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: AppTheme.surfaceNavy,
              side: BorderSide(color: AppTheme.accentIndigo.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(
              Icons.smart_toy_outlined,
              color: AppTheme.accentIndigo,
              size: 20,
            ),
            label: const Text(
              'Hỏi Trợ lý AI',
              style: TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () => widget.onNavigateTab(4), // Tab AI Assistant
          ),
        ),
      ],
    );
  }

  // --- 5. Scientific Sleep Quote Card ---
  Widget _buildSleepQuoteCard() {
    final quoteItem = _sleepQuotes[_quoteIndex];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surfaceNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardNavy.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppTheme.softAmber, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Khoa học Giấc ngủ & Trích dẫn',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.softAmber,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _nextQuote,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Đổi câu khác', style: TextStyle(fontSize: 11, color: AppTheme.accentCyan)),
                      SizedBox(width: 2),
                      Icon(Icons.refresh, size: 14, color: AppTheme.accentCyan),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${quoteItem['quote']!}"',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textLight,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${quoteItem['author']!}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Latest Sleep Record Card ---
  Widget _buildLatestRecordCard(BuildContext context, dynamic record) {
    return Card(
      color: AppTheme.surfaceNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.cardNavy.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nhật Ký Giấc Ngủ Gần Nhất',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                if (record != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: record.isGoalMet
                          ? AppTheme.softGreen.withValues(alpha: 0.2)
                          : AppTheme.softRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      record.isGoalMet ? 'Đạt mục tiêu ✓' : 'Chưa đạt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: record.isGoalMet
                            ? AppTheme.softGreen
                            : AppTheme.softRed,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (record == null)
              const Text(
                'Chưa có dữ liệu nhật ký. Hãy bắt đầu ghi nhận giấc ngủ hôm nay nhé!',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled, size: 16, color: AppTheme.accentCyan),
                      const SizedBox(width: 6),
                      Text(
                        'Thời lượng: ${TimeUtils.formatDuration(record.durationHours)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Từ: ${TimeUtils.formatDateTime(record.sleepTime)} đến ${TimeUtils.formatDateTime(record.wakeTime)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Cảm nhận thức dậy: ', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      Text(
                        '⭐' * record.feelingRating,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
