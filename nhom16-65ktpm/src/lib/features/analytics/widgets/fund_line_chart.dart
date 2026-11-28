import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../analytics_service.dart';

/// Chọn khoảng tick "tròn" cho trục tung theo độ lớn của giá trị lớn nhất,
/// đồng thời làm tròn maxY lên bội của khoảng tick — để các nhãn trục
/// cách đều nhau và không bị đè (lỗi lộ ra khi số liệu thật lên hàng triệu).
(double, double) _axisScale(double rawMax) {
  final max = rawMax <= 0 ? 100000.0 : rawMax;
  final interval = max > 1000000
      ? 500000.0
      : max > 200000
      ? 100000.0
      : max > 50000
      ? 20000.0
      : max > 10000
      ? 5000.0
      : 1000.0;
  var maxY = (max / interval).ceil() * interval;
  if (maxY <= max) maxY += interval;
  return (interval, maxY);
}

/// Biểu đồ đường: biến động số dư quỹ 7 ngày gần nhất.
class FundLineChart extends StatelessWidget {
  const FundLineChart({super.key, required this.points});

  final List<BalancePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Chưa đủ dữ liệu để vẽ biểu đồ.')),
      );
    }
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].balance),
    ];
    final maxBalance = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final (interval, maxY) = _axisScale(maxBalance);
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(show: true, horizontalInterval: interval),
          borderData: FlBorderData(show: true),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => Text(
                  '${(value / 1000).round()}k',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    points[i].label,
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
