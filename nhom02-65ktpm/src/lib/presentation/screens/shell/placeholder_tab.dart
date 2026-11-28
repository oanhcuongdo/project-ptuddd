import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';

/// Màn hình tạm cho các tab chưa được phát triển.
/// Mỗi phân hệ sẽ thay thế placeholder này bằng màn hình thật.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(AppStrings.comingSoon, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
