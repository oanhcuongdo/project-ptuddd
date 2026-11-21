import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';

class PronunciationScreen extends StatelessWidget {
  const PronunciationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassScaffold(
      appBar: GlassAppBar(title: Text('Luyện Phát Âm')),
      body: ComingSoonView(
        icon: Icons.mic_none_outlined,
        color: AppColors.fig,
        title: 'Chấm Phát Âm Offline & Azure Speech',
        message: 'Đang phát triển theo phân công Issue #15 của Khanh',
      ),
    );
  }
}
