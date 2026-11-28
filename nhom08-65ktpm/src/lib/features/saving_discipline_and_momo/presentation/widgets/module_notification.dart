import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Semantic tone for floating in-module notifications.
enum ModuleNotificationTone { success, info, warning, error }

/// Unified floating SnackBar notification helper for Module 2.
class ModuleNotification {
  const ModuleNotification._();

  static void show(
    BuildContext context, {
    required String message,
    ModuleNotificationTone tone = ModuleNotificationTone.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final (bg, border, fg, icon) = switch (tone) {
      ModuleNotificationTone.success => (
          AppColors.mintContainer,
          AppColors.mint,
          AppColors.onMintContainer,
          Icons.check_circle_rounded,
        ),
      ModuleNotificationTone.info => (
          AppColors.primaryContainer,
          AppColors.primary,
          AppColors.onPrimaryContainer,
          Icons.info_rounded,
        ),
      ModuleNotificationTone.warning => (
          AppColors.amberContainer,
          AppColors.amber,
          AppColors.onAmberContainer,
          Icons.warning_amber_rounded,
        ),
      ModuleNotificationTone.error => (
          AppColors.errorContainer,
          AppColors.error,
          AppColors.onErrorContainer,
          Icons.error_outline_rounded,
        ),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration,
          backgroundColor: bg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: border),
          ),
          content: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, tone: ModuleNotificationTone.success);

  static void info(BuildContext context, String message) =>
      show(context, message: message, tone: ModuleNotificationTone.info);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, tone: ModuleNotificationTone.warning);

  static void error(BuildContext context, String message) =>
      show(context, message: message, tone: ModuleNotificationTone.error);
}
