import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'kid_status_icon.dart';

/// Vùng hiển thị trạng thái / Banner thông báo dùng chung (KidStatusBanner).
///
/// Hỗ trợ:
/// - 4 loại trạng thái: success, warning, error, info.
/// - Biểu tượng trực quan Zero-Text UI lớn, dễ hiểu cho trẻ nhỏ 4–6 tuổi.
/// - Tùy chọn nút hành động (action) và nút đóng (dismiss).
/// - Vùng chạm chuẩn WCAG >= 48dp.
/// - Tái sử dụng trong Home Screen (nhắc giờ học, streak banner), Parental Gate và Parent Dashboard.
class KidStatusBanner extends StatelessWidget {
  final KidStatusType status;
  final String title;
  final String? subtitle;
  final String? iconEmoji;
  final IconData? iconData;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry margin;

  const KidStatusBanner({
    super.key,
    required this.status,
    required this.title,
    this.subtitle,
    this.iconEmoji,
    this.iconData,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  Color get _baseColor {
    switch (status) {
      case KidStatusType.success:
        return AppColors.success;
      case KidStatusType.warning:
        return AppColors.primary; // Gam cam đất ấm áp
      case KidStatusType.error:
        return AppColors.error;
      case KidStatusType.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _baseColor;

    return Semantics(
      container: true,
      label: '$title. ${subtitle ?? ''}',
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: color.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Biểu tượng trực quan (Emoji hoặc Icon)
            if (iconEmoji != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  iconEmoji!,
                  style: const TextStyle(fontSize: 28),
                ),
              )
            else if (iconData != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(iconData, color: color, size: 28),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: KidStatusIcon(status: status, size: 48),
              ),

            // Nội dung thông báo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onAction!();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          actionLabel!,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: color,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Nút đóng thông báo (Dismiss button)
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                iconSize: 20,
                color: AppColors.textLight,
                tooltip: 'Đóng',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onDismiss!();
                },
              ),
          ],
        ),
      ),
    );
  }
}
