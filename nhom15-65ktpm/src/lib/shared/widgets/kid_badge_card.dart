import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../entities/badge_item.dart';

/// Thẻ hiển thị huy hiệu dùng chung (KidBadgeCard) trong hệ thống Zero-Text UI.
///
/// Hỗ trợ:
/// - Hiển thị trạng thái đã mở khóa (rực rỡ, ánh vàng) hoặc chưa mở (mờ xám).
/// - Vùng chạm tối thiểu 48x48dp (WCAG AA).
/// - Hiệu ứng nảy xúc giác khi ấn kèm rung HapticFeedback.
/// - Tái sử dụng linh hoạt trong Gamification, Home Screen, Badge Dialog và Parent Dashboard.
class KidBadgeCard extends StatefulWidget {
  final BadgeItem badge;
  final bool isUnlocked;
  final VoidCallback? onTap;
  final double size;
  final bool showDescription;

  const KidBadgeCard({
    super.key,
    required this.badge,
    required this.isUnlocked,
    this.onTap,
    this.size = 100.0,
    this.showDescription = false,
  }) : assert(size >= AppDimensions.minTouchSize);

  @override
  State<KidBadgeCard> createState() => _KidBadgeCardState();
}

class _KidBadgeCardState extends State<KidBadgeCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = widget.isUnlocked;
    final badge = widget.badge;

    final borderColor = isUnlocked
        ? AppColors.secondary.withValues(alpha: 0.85)
        : Colors.grey.shade300;

    final backgroundColor = isUnlocked ? Colors.white : AppColors.surface;

    final shadowColor = isUnlocked
        ? AppColors.secondary.withValues(alpha: 0.25)
        : Colors.transparent;

    final statusText = isUnlocked ? 'Đã đạt' : 'Chưa mở';
    final semanticMessage =
        'Huy hiệu ${badge.title}: $statusText. ${badge.description}';

    return Semantics(
      label: semanticMessage,
      button: widget.onTap != null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Material(
          color: backgroundColor,
          elevation: isUnlocked ? 2.5 : 0.5,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: InkWell(
            onTap: widget.onTap != null
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onTap!();
                  }
                : null,
            onTapDown: (_) {
              if (widget.onTap != null) setState(() => _scale = 0.95);
            },
            onTapUp: (_) {
              if (widget.onTap != null) setState(() => _scale = 1.0);
            },
            onTapCancel: () {
              if (widget.onTap != null) setState(() => _scale = 1.0);
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: Container(
              constraints: const BoxConstraints(
                minWidth: AppDimensions.minTouchSize,
                minHeight: AppDimensions.minTouchSize,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSmall,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: borderColor,
                  width: isUnlocked ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Biểu tượng huy hiệu (Emoji / Icon lớn)
                  Text(
                    badge.icon,
                    style: TextStyle(
                      fontSize: 34,
                      color: isUnlocked ? null : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Tên huy hiệu
                  Text(
                    badge.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? AppColors.textDark
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Trạng thái đã đạt / chưa mở
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked
                          ? AppColors.success
                          : Colors.grey.shade400,
                    ),
                  ),
                  if (widget.showDescription) ...[
                    const SizedBox(height: 4),
                    Text(
                      badge.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
