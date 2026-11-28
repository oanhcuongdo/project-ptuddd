import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Nhãn nhỏ (tag, môn học, bộ lọc) dùng chung.
///
/// Mặc định dùng `secondaryContainer`; khi đặt trên thẻ pastel, truyền [tone]
/// để nhãn cùng tông với thẻ (tham chiếu
/// `02_notes_google_keep_inspired.png`). Không nhận mã màu tuỳ ý.
class TagChip extends StatelessWidget {
  const TagChip({required this.label, this.icon, this.tone, super.key});

  final String label;
  final IconData? icon;
  final AppNoteTone? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = tone == null
        ? scheme.secondaryContainer
        : tone!.accent.withValues(alpha: 0.16);
    final foreground = tone == null
        ? scheme.onSecondaryContainer
        : tone!.accent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
