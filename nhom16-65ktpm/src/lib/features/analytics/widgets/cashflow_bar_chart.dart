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

/// Biểu đồ cột: thu (xanh) / chi (đỏ) theo tháng.
class CashflowBarChart extends StatelessWidget {
  const CashflowBarChart({super.key, required this.points});

  final List<MonthPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Chưa có dữ liệu thu/chi.')),
      );
    }
    final maxVal = points
        .expand((p) => [p.income, p.expense])
        .reduce((a, b) => a > b ? a : b);
    final (interval, maxY) = _axisScale(maxVal);
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
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
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: [
                  BarChartRodData(
                    toY: points[i].income,
                    color: Colors.green,
                    width: 14,
                  ),
                  BarChartRodData(
                    toY: points[i].expense,
                    color: Colors.red,
                    width: 14,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
