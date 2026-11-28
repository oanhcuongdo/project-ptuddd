import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Khung màn dùng chung với header phân tầng (tham chiếu mockup
/// `02_notes_google_keep_inspired.png`): dòng chào nhỏ, tiêu đề lớn cố định vị
/// trí, phụ đề, vùng toolbar cho tìm kiếm/bộ lọc, rồi tới nội dung.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.eyebrow,
    this.subtitle,
    this.actions = const <Widget>[],
    this.toolbar,
    this.floatingActionButton,
    super.key,
  });

  final String title;

  /// Dòng nhỏ phía trên tiêu đề (ví dụ lời chào theo buổi).
  final String? eyebrow;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? toolbar;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: actions,
        backgroundColor: scheme.surface,
        titleSpacing: 0,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (eyebrow != null) ...<Widget>[
                    Text(
                      eyebrow!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(title, style: theme.textTheme.displaySmall),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (toolbar != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: toolbar,
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
