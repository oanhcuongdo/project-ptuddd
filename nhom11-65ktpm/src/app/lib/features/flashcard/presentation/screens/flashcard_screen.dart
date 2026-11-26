import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';

class FlashcardScreen extends StatelessWidget {
  const FlashcardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassScaffold(
      appBar: GlassAppBar(title: Text('Flashcard Ôn Tập')),
      body: ComingSoonView(
        icon: Icons.style_outlined,
        color: AppColors.secondaryDark,
        title: 'Ôn Tập Ngắt Quãng SM-2',
        message: 'Đang phát triển theo phân công Issue #20 của Hoa',
      ),
    );
  }
}
