import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Nhãn đặt **phía trên** ô nhập liệu (tham chiếu Duolingo).
///
/// Form dùng nhãn ngoài thay cho `labelText` bên trong ô, để chữ không bị cắt
/// khi ô đã có nội dung — xem `docs/ui_ux.md` mục 3.3.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: theme.textTheme.labelLarge),
    );
  }
}
