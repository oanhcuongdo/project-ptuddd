import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_loading_indicator.dart';

/// Nút hành động chính — tham chiếu `13_design_system.png`: nền `primary`,
/// bo [AppRadius.button], cao [AppSizes.buttonHeight], bóng màu nhẹ thay cho
/// viền "3D" cứng.
///
/// Mỗi màn chỉ có **một** nút loại này (hành động chính) — xem
/// `docs/ui_ux.md` mục 5.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !isLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: enabled
            ? AppShadows.primary(scheme.primary)
            : const <BoxShadow>[],
      ),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: isLoading
              ? AppLoadingIndicator(key: const ValueKey<String>('loading'))
              : Text(label, key: const ValueKey<String>('label')),
        ),
      ),
    );
  }
}
