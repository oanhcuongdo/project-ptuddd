import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppBadgeTone { primary, mint, amber, error, momo, neutral }

/// Nhãn trạng thái dạng pill đồng bộ trên toàn bộ 4 module.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
  });

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AppBadgeTone.primary => (AppColors.primaryContainer, AppColors.onPrimaryContainer),
      AppBadgeTone.mint => (AppColors.mintContainer, AppColors.onMintContainer),
      AppBadgeTone.amber => (AppColors.amberContainer, AppColors.onAmberContainer),
      AppBadgeTone.error => (AppColors.errorContainer, AppColors.onErrorContainer),
      AppBadgeTone.momo => (AppColors.momoContainer, AppColors.onMomoContainer),
      AppBadgeTone.neutral => (AppColors.surfaceContainerHigh, AppColors.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
