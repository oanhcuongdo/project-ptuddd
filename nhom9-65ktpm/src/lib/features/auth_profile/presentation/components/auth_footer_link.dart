import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Component dòng chuyển trang ở cuối form Auth (Đăng nhập <-> Đăng ký)
class AuthFooterLink extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AuthFooterLink({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: TextButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
