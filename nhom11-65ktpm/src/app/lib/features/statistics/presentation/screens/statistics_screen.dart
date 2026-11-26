import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassScaffold(
      appBar: GlassAppBar(title: Text('Thống Kê Tiến Độ')),
      body: ComingSoonView(
        icon: Icons.insights_outlined,
        color: AppColors.cactus,
        title: 'Biểu Đồ Học Tập fl_chart & Bảng Xếp Hạng',
        message: 'Đang phát triển theo phân công Issue #33 của Bảo',
      ),
    );
  }
}
