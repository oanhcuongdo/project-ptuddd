import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../services/analytics_service.dart';
import 'reminder_screen.dart';

/// Màn hình Thống kê Phong độ Cầu thủ & Báo cáo Thể lực (Analytics)
/// Tác giả: Nguyễn Hồng Thái (Phân hệ 5 - Thống kê & Nhắc lịch ra sân)
class AnalyticsScreen extends StatefulWidget {
  final String userId;
  const AnalyticsScreen({super.key, this.userId = ''});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = true;
  late OverallSummaryReport _summary;
  late List<WeeklyFitnessStat> _weeklyStats;
  late List<HeatmapDayData> _monthlyHeatmap;

  int _selectedDayIndex = 6; // Mặc định chọn ngày hôm nay trong biểu đồ cột

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _analyticsService.getOverallSummary(widget.userId);
      final weekly = await _analyticsService.get7DayFitnessStats(widget.userId);
      final heatmap = await _analyticsService.getMonthlyHeatmap(widget.userId);

      if (mounted) {
        setState(() {
          _summary = summary;
          _weeklyStats = weekly;
          _monthlyHeatmap = heatmap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Thống Kê Phong Độ Cầu Thủ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Nhắc lịch ra sân',
            icon: const Icon(Icons.alarm_on, color: Color(0xFF10B981)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReminderScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : RefreshIndicator(
              color: const Color(0xFF10B981),
              backgroundColor: const Color(0xFF1E293B),
              onRefresh: _loadAnalyticsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlayerHeroHeader(),
                    const SizedBox(height: 20),
                    _buildKpiSummaryGrid(),
                    const SizedBox(height: 24),
                    _buildWeeklyFitnessBarChartSection(),
                    const SizedBox(height: 24),
                    _buildMonthlyDisciplineHeatmapSection(),
                    const SizedBox(height: 24),
                    _buildQuickActionToReminders(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  /// Tiêu đề giới thiệu phân hệ
  Widget _buildPlayerHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.insights, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Báo Cáo Hiệu Suất Thể Lực',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Phân hệ 5: Thống kê & Nhắc lịch ra sân (Nguyễn Hồng Thái)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Khối 4 thẻ chỉ số KPIs (Thời gian tập, Trận đấu, Phong độ, Kỷ luật)
  Widget _buildKpiSummaryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CHỈ SỐ THI ĐẤU & HUẤN LUYỆN',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Tổng phút tập',
                value: '${_summary.totalTrainingMinutesWeek}p',
                subText: '${_summary.totalTrainingMinutesMonth}p tháng này',
                icon: Icons.timer,
                accentColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Trận ra sân',
                value: '${_summary.totalMatches}',
                subText: '${_summary.totalGoals} bàn, ${_summary.totalAssists} kiến tạo',
                icon: Icons.sports_soccer,
                accentColor: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Điểm phong độ',
                value: '${_summary.averageRating} ⭐',
                subText: 'Đánh giá sau trận',
                icon: Icons.star_rate_rounded,
                accentColor: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Kỷ luật rèn luyện',
                value: '${_summary.disciplineRateMonth}%',
                subText: '${_summary.currentStreakDays} ngày Streak 🔥',
                icon: Icons.local_fire_department,
                accentColor: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: TextStyle(color: accentColor.withValues(alpha: 0.9), fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 1. BIỂU ĐỒ CỘT THỂ LỰC 7 NGÀY QUA (Weekly Fitness Chart)
  Widget _buildWeeklyFitnessBarChartSection() {
    final maxMinutes = _weeklyStats.fold<int>(
      60,
      (max, e) => e.durationMinutes > max ? e.durationMinutes : max,
    );

    final selectedStat = _weeklyStats[_selectedDayIndex.clamp(0, _weeklyStats.length - 1)];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biểu Đồ Cột Thể Lực 7 Ngày Qua',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Thời lượng tập luyện theo từng ngày (phút)',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${selectedStat.durationMinutes} phút (${selectedStat.dayName})',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),

          // Khối vẽ các cột biểu đồ
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_weeklyStats.length, (index) {
                final stat = _weeklyStats[index];
                final isSelected = index == _selectedDayIndex;
                final heightFactor = (stat.durationMinutes / (maxMinutes > 0 ? maxMinutes : 1)).clamp(0.1, 1.0);

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedDayIndex = index);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${stat.durationMinutes}p',
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF10B981) : Colors.white38,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 110 * heightFactor,
                          width: 26,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isSelected
                                  ? [const Color(0xFF34D399), const Color(0xFF10B981)]
                                  : [const Color(0xFF059669).withValues(alpha: 0.6), const Color(0xFF064E3B)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stat.dayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số bài drill hoàn thành: ${selectedStat.drillsCount} bài',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Text(
                'Mục tiêu: >= 45p/ngày',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. LƯỚI LỊCH NHIỆT HEATMAP KỶ LUẬT CẢ THÁNG (Monthly Heatmap Grid)
  Widget _buildMonthlyDisciplineHeatmapSection() {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lưới Nhiệt Kỷ Luật Tháng ${now.month}/${now.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tỷ lệ hoàn thành thói quen rèn luyện hàng ngày',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const Icon(Icons.calendar_month, color: Color(0xFF10B981), size: 22),
            ],
          ),
          const SizedBox(height: 18),

          // Hàng tiêu đề các thứ trong tuần
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((day) {
              return SizedBox(
                width: 38,
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Lưới ô vuông heatmap theo các ngày trong tháng
          _buildHeatmapGrid(),

          const SizedBox(height: 18),
          const Divider(color: Colors.white12),

          // Chú thích độ đậm nhạt (Heatmap Legend)
          Row(
            children: [
              const Text('Nghỉ', style: TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(width: 8),
              _buildLegendBox(const Color(0xFF1F2937)),
              const SizedBox(width: 4),
              _buildLegendBox(const Color(0xFF064E3B)),
              const SizedBox(width: 4),
              _buildLegendBox(const Color(0xFF047857)),
              const SizedBox(width: 4),
              _buildLegendBox(const Color(0xFF059669)),
              const SizedBox(width: 4),
              _buildLegendBox(const Color(0xFF10B981)),
              const SizedBox(width: 8),
              const Text('100% Kỷ luật', style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    if (_monthlyHeatmap.isEmpty) return const SizedBox.shrink();

    // Xác định thứ của ngày mùng 1 trong tháng (1 = Thứ 2, 7 = Chủ nhật)
    final firstDayWeekday = _monthlyHeatmap.first.date.weekday;
    final leadingEmptyBoxes = firstDayWeekday - 1;

    final totalBoxes = leadingEmptyBoxes + _monthlyHeatmap.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(totalBoxes, (index) {
        if (index < leadingEmptyBoxes) {
          return const SizedBox(width: 38, height: 38);
        }

        final dataIndex = index - leadingEmptyBoxes;
        final data = _monthlyHeatmap[dataIndex];
        final color = _getHeatmapColor(data.intensityLevel);

        return Tooltip(
          message: 'Ngày ${data.date.day}: hoàn thành ${data.completedCount}/${data.totalCount} bài tập',
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: data.intensityLevel == 4 ? const Color(0xFF34D399).withValues(alpha: 0.5) : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                '${data.date.day}',
                style: TextStyle(
                  color: data.intensityLevel > 0 ? Colors.white : Colors.white24,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Color _getHeatmapColor(int intensity) {
    switch (intensity) {
      case 1:
        return const Color(0xFF064E3B);
      case 2:
        return const Color(0xFF047857);
      case 3:
        return const Color(0xFF059669);
      case 4:
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF1F2937); // Mức 0: Xám đậm
    }
  }

  /// Thẻ chuyển tiếp sang Quản lý lịch nhắc nhở ra sân
  Widget _buildQuickActionToReminders() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReminderScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.alarm_add_rounded, color: Color(0xFF3B82F6), size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cài Đặt Lịch Nhắc Nhở Ra Sân',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hẹn giờ xách giày đi tập, thông báo giãn cơ & nghỉ ngơi',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
