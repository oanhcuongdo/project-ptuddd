import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/note_summary.dart';
import 'summary_mode_labels.dart';

/// Khối kết quả tóm tắt: nội dung, số từ, thời gian chờ và nút sao chép.
class SummaryResultCard extends StatelessWidget {
  const SummaryResultCard({required this.summary, this.elapsed, super.key});

  final NoteSummary summary;

  /// Thời gian từ lúc gọi đến lúc có kết quả (tiêu chí ~15 giây của #12).
  final Duration? elapsed;

  String get _meta {
    final parts = <String>['${summary.wordCount} từ', summary.mode.label];
    if (elapsed != null) {
      final seconds = (elapsed!.inMilliseconds / 1000)
          .toStringAsFixed(1)
          .replaceAll('.', ',');
      parts.add('xong trong $seconds giây');
    }
    return parts.join(' · ');
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: summary.content));
    if (!context.mounted) {
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Đã sao chép bản tóm tắt.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Kết quả tóm tắt',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Sao chép',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copy(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(summary.content, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          Text(
            _meta,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
