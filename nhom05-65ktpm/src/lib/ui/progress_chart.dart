import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../data/app_database.dart';

/// Daily mean pronunciation score chart for one learner profile.
class ProgressScoreChart extends StatelessWidget {
  final int userId;

  const ProgressScoreChart({super.key, required this.userId});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<DailyScore>>(
    future: context.read<AppState>().db.dailyAverageScores(userId, days: 7),
    builder: (context, snapshot) {
      final theme = Theme.of(context);
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final scores = snapshot.data ?? const <DailyScore>[];
      if (scores.isEmpty) {
        return const Card(
          child: SizedBox(
            height: 130,
            child: Center(
              child: Text(
                'Complete a practice session to see your score trend.',
              ),
            ),
          ),
        );
      }
      final spots = [
        for (final score in scores)
          FlSpot(
            DateTime.parse(score.date).millisecondsSinceEpoch.toDouble(),
            score.averageScore,
          ),
      ];
      final minX = spots.first.x;
      final maxX = spots.last.x == minX
          ? minX + Duration.millisecondsPerDay
          : spots.last.x;
      return SizedBox(
        height: 210,
        child: LineChart(
          LineChartData(
            minX: minX,
            maxX: maxX,
            minY: 0,
            maxY: 100,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 34),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: Duration.millisecondsPerDay.toDouble(),
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      value.toInt(),
                    );
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${date.month}/${date.day}',
                        style: theme.textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (items) => [
                  for (final item in items)
                    LineTooltipItem(
                      '${DateTime.fromMillisecondsSinceEpoch(item.x.toInt()).month}/'
                      '${DateTime.fromMillisecondsSinceEpoch(item.x.toInt()).day}: '
                      '${item.y.toStringAsFixed(1)} (${scores[item.spotIndex].attemptCount} tries)',
                      TextStyle(color: theme.colorScheme.onInverseSurface),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: theme.colorScheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
