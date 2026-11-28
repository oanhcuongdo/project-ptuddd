import 'package:flutter/material.dart';

import 'empty_state.dart';

/// Trạng thái lỗi dùng chung: thông báo tiếng Việt + nút "Thử lại".
///
/// Dùng cho mọi màn đọc dữ liệu để lỗi hiển thị đồng nhất — xem
/// `docs/ui_ux.md` mục 2.
class ErrorView extends StatelessWidget {
  const ErrorView({
    required this.message,
    this.title = 'Không tải được dữ liệu',
    this.icon = Icons.cloud_off_rounded,
    this.onRetry,
    super.key,
  });

  final String message;
  final String title;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: onRetry == null ? null : 'Thử lại',
      onAction: onRetry,
    );
  }
}
