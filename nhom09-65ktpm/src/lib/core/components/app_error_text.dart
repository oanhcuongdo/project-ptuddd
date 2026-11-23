import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Component hiển thị thông báo lỗi form dùng chung
class AppErrorText extends StatelessWidget {
  final String? message;

  const AppErrorText({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(message!, style: AppTextStyles.error),
    );
  }
}
