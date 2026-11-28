import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';

/// Dòng "Gợi ý mang tính tham khảo" (bắt buộc hiển thị cạnh gợi ý).
class DisclaimerNote extends StatelessWidget {
  const DisclaimerNote({super.key, this.full = false});

  /// true: hiển thị câu đầy đủ (không thay thế tư vấn chuyên gia).
  final bool full;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            full ? AppStrings.disclaimerFull : AppStrings.disclaimerShort,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
