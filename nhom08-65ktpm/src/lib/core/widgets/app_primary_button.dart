import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Nút CTA chính cao 48px, bo góc 12px (hỗ trợ nền Primary #007AFF hoặc MoMo #A50064).
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.onPrimary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
