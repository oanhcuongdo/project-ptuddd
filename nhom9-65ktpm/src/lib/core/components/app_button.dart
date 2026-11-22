import 'package:flutter/material.dart';

import '../../features/auth_profile/presentation/styles/auth_styles.dart';

/// Component nút bấm chính dạng bo tròn (Pill) dùng chung toàn app
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (isLoading) {
      content = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color: Colors.white,
        ),
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(trailingIcon, size: 20),
          ],
        ],
      );
    }

    return DecoratedBox(
      decoration: onPressed != null && !isLoading
          ? AuthStyles.primaryButtonShadow
          : const BoxDecoration(),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: content,
      ),
    );
  }
}
