import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Màn hình khung (placeholder) dùng chung cho các module chức năng.
/// Thiết kế thanh lịch, gọn gàng, thể hiện rõ phân công module cho các thành viên.
class ModulePlaceholderScreen extends StatelessWidget {
  final String moduleTitle;
  final String assignee;
  final String description;
  final IconData icon;
  final List<Widget>? actions;

  const ModulePlaceholderScreen({
    super.key,
    required this.moduleTitle,
    required this.assignee,
    required this.description,
    required this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: Text(moduleTitle),
        actions: actions,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      size: 34,
                      color: AppColors.primaryAction,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    moduleTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Phụ trách: $assignee',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryAction,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),

                  const Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Icon(
                        Icons.construction_rounded,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      Text(
                        'Module đang trong quá trình phát triển',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
