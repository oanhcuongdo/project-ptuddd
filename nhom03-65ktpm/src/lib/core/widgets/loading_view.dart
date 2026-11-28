import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Khung chờ dạng skeleton (các thẻ xám) cho màn danh sách.
///
/// Không dùng package shimmer để giữ dependency tối thiểu; hiệu ứng chỉ là
/// các khối màu `surfaceContainerHigh`.
class LoadingView extends StatelessWidget {
  const LoadingView({this.itemCount = 4, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, int index) {
        return Container(
          height: index.isEven ? 104 : 88,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        );
      },
    );
  }
}
