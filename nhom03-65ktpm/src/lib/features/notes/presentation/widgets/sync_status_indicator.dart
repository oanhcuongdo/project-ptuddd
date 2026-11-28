import 'package:flutter/material.dart';

import '../../../../core/sync/sync_status.dart';

/// Chỉ báo trạng thái đồng bộ đa thiết bị (#21, tiêu chí 3).
///
/// - `disabled`: chưa cấu hình Supabase → không hiển thị gì (app chỉ lưu máy).
/// - `syncing`: icon xoay nhẹ + nhãn \"Đang đồng bộ\".
/// - `synced`: icon đám mây có dấu kiểm.
/// - `error`: icon đám mây gạch chéo, chạm để thử lại (nếu có [onRetry]).
///
/// Nhãn luôn đi kèm `Tooltip` + `Semantics` để trình đọc màn hình đọc được,
/// không chỉ dựa vào màu.
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    required this.status,
    this.message,
    this.onRetry,
    super.key,
  });

  final SyncStatus status;
  final String? message;
  final VoidCallback? onRetry;

  String get _label => switch (status) {
    SyncStatus.disabled => 'Chỉ lưu trên máy',
    SyncStatus.syncing => 'Đang đồng bộ',
    SyncStatus.synced => 'Đã đồng bộ',
    SyncStatus.error => 'Lỗi đồng bộ',
  };

  IconData get _icon => switch (status) {
    SyncStatus.disabled => Icons.cloud_off_rounded,
    SyncStatus.syncing => Icons.sync_rounded,
    SyncStatus.synced => Icons.cloud_done_rounded,
    SyncStatus.error => Icons.cloud_off_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.disabled) {
      return const SizedBox.shrink();
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = switch (status) {
      SyncStatus.syncing => scheme.onSurfaceVariant,
      SyncStatus.synced => scheme.primary,
      SyncStatus.error => scheme.error,
      SyncStatus.disabled => scheme.onSurfaceVariant,
    };

    final Widget icon = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(_icon, size: 20, color: color, semanticLabel: _label),
    );

    final String tooltip = status == SyncStatus.error && message != null
        ? '$_label — $message'
        : _label;

    if (status == SyncStatus.error && onRetry != null) {
      return Tooltip(
        message: '$tooltip. Chạm để thử lại.',
        child: IconButton(
          onPressed: onRetry,
          icon: Icon(_icon, size: 20, color: color),
          tooltip: _label,
        ),
      );
    }

    return Tooltip(message: tooltip, child: icon);
  }
}
