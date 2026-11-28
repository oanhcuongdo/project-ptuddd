import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/summary_mode.dart';
import 'summary_mode_labels.dart';

/// Hàng chip chọn kiểu tóm tắt (ngắn / dài / gạch ý chính).
///
/// Cuộn ngang để không tràn trên máy hẹp, cùng nhịp với hàng chip lọc môn ở
/// màn ghi chú.
class SummaryModeSelector extends StatelessWidget {
  const SummaryModeSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final SummaryMode selected;
  final ValueChanged<SummaryMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final mode in SummaryMode.values) ...<Widget>[
            if (mode != SummaryMode.values.first)
              const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: Text(mode.label),
              avatar: Icon(mode.icon),
              showCheckmark: false,
              selected: mode == selected,
              onSelected: (_) => onSelected(mode),
            ),
          ],
        ],
      ),
    );
  }
}
