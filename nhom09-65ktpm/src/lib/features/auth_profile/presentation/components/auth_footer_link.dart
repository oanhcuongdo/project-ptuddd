import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../styles/auth_styles.dart';

/// Component dòng chuyển trang ở chân màn hình Auth (dùng Wrap chống tràn viền 100%)
class AuthFooterLink extends StatelessWidget {
  final String prefixText;
  final String actionText;
  final VoidCallback? onPressed;

  const AuthFooterLink({
    super.key,
    required this.prefixText,
    required this.actionText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(
          prefixText,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              actionText,
              style: AuthStyles.linkAction.copyWith(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
