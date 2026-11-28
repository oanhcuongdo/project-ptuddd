import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../providers/sleep_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sleepProv = context.watch<SleepProvider>();
    final records = sleepProv.records.take(7).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống Kê & Đánh Giá Kỷ Luật'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Overview Metric Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Độ tuân thủ mục tiêu',
                    value: '${sleepProv.complianceRate.round()}%',
                    icon: Icons.check_circle_outline,
                    color: AppTheme.softGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Trung bình 7 ngày',
                    value: TimeUtils.formatDuration(sleepProv.averageDurationHours),
                    icon: Icons.access_time,
                    color: AppTheme.accentCyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Bar Chart of 7 Days Sleep Duration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thời Lượng Ngủ 7 Ngày Qua (Giờ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('Đường đứt nét màu vàng là mục tiêu ngủ của bạn.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 220,
                      child: records.isEmpty
                          ? const Center(child: Text('Chưa có đủ dữ liệu thống kê.'))
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 12,
                                barTouchData: BarTouchData(enabled: true),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (val, meta) {
                                        final idx = val.toInt();
                                        if (idx >= 0 && idx < records.length) {
                                          final dt = records[idx].wakeTime;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text('${dt.day}/${dt.month}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                          );
                                        }
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 2,
                                      getTitlesWidget: (val, meta) => Text('${val.toInt()}h', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: const FlGridData(show: true, drawVerticalLine: false),
                                borderData: FlBorderData(show: false),
                                barGroups: List.generate(records.length, (index) {
                                  final dur = records[index].durationHours;
                                  final isMet = records[index].isGoalMet;
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: dur,
                                        color: isMet ? AppTheme.accentCyan : AppTheme.softAmber,
                                        width: 18,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Discipline Criteria Explanation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Tiêu Chí Đánh Giá Kỷ Luật Giấc Ngủ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    SizedBox(height: 8),
                    Text(
                      '• Điểm kỷ luật được tính dựa trên tỷ lệ số ngày bạn đạt được thời lượng ngủ mục tiêu (chênh lệch dưới 30 phút).\n'
                      '• Chỉ số này mang tính chất theo dõi thói quen sinh hoạt cá nhân, không phải là chẩn đoán y tế.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
