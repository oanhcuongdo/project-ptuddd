import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Tiêu đề mục viết hoa màu xám nằm phía trên mỗi AppInsetCard.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
