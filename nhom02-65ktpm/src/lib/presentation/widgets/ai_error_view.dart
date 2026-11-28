import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/result.dart';
import '../../core/strings/app_strings.dart';
import '../../core/strings/scan_strings.dart';

/// Hiển thị lỗi AI thân thiện + LUÔN có lối thoát sang nhập thủ công.
class AiErrorView extends StatelessWidget {
  const AiErrorView({
    super.key,
    required this.failure,
    required this.onManual,
    this.onRetry,
    this.retryLabel = AppStrings.retry,
    this.manualLabel = ScanStrings.manualEntry,
  });

  final AppFailure failure;
  final VoidCallback onManual;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String manualLabel;

  IconData get _icon => switch (failure.type) {
        FailureType.network => Icons.wifi_off_rounded,
        FailureType.timeout => Icons.timer_off_outlined,
        FailureType.quotaExceeded || FailureType.rateLimited => Icons.hourglass_bottom_rounded,
        FailureType.appCheck => Icons.shield_outlined,
        FailureType.notRecognized => Icons.image_search_outlined,
        _ => Icons.sentiment_neutral_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = failure.message.isNotEmpty ? failure.message : ScanStrings.unknown;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 48, color: theme.colorScheme.secondary),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        // Gợi ý kiểm tra App Check chỉ hiện ở bản debug.
        if (kDebugMode && failure.type == FailureType.appCheck) ...[
          const SizedBox(height: 8),
          Text(
            ScanStrings.appCheckDebugHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onManual,
              icon: const Icon(Icons.edit_note),
              label: Text(manualLabel),
            ),
            if (onRetry != null)
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
              ),
          ],
        ),
      ],
    );
  }
}
