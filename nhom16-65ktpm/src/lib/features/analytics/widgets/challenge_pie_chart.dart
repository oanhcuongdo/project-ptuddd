import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../analytics_service.dart';

/// Biểu đồ tròn: tỷ trọng đóng góp theo danh mục.
/// Chặn chia cho 0: tổng bằng 0 thì hiện trạng thái trống, không vẽ.
class ChallengePieChart extends StatelessWidget {
  const ChallengePieChart({super.key, required this.shares});

  final List<ChallengeShare> shares;

  static const _colors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    final total = shares.fold<double>(0, (s, e) => s + e.amount);
    if (shares.isEmpty || total <= 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Chưa có đóng góp theo danh mục.')),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                for (var i = 0; i < shares.length; i++)
                  PieChartSectionData(
                    value: shares[i].amount,
                    color: _colors[i % _colors.length],
                    title:
                        '${(shares[i].amount / total * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < shares.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: _colors[i % _colors.length],
                ),
                const SizedBox(width: 8),
                Text(shares[i].challenge),
              ],
            ),
          ),
      ],
    );
  }
}
