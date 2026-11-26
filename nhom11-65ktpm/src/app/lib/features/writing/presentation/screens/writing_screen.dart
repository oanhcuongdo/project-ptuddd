import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';

class WritingScreen extends StatelessWidget {
  const WritingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassScaffold(
      appBar: GlassAppBar(title: Text('Luyện Viết Hán Tự')),
      body: ComingSoonView(
        icon: Icons.brush_outlined,
        color: AppColors.heather,
        title: 'Khung Ô Chữ & Kiểm Tra Thứ Tự Nét',
        message: 'Đang phát triển theo phân công Issue #26 của Đệ',
      ),
    );
  }
}
