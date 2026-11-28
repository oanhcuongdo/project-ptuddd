import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Thẻ chức năng dùng chung (KidCard) trong hệ thống Zero-Text UI.
///
/// Hỗ trợ:
/// - Vùng chạm tối thiểu 48x48dp theo chuẩn tiếp cận trẻ em (WCAG).
/// - Hiệu ứng nảy xúc giác (AnimatedScale) khi nhấn kèm rung HapticFeedback.
/// - Trạng thái được chọn (isSelected) với viền nổi bật.
/// - Tương thích mượt mà trên Mobile, Web Chrome và Windows Desktop.
class KidCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isSelected;
  final Border? border;
  final double elevation;

  const KidCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.color = AppColors.cardBg,
    this.padding = const EdgeInsets.all(AppDimensions.paddingMedium),
    this.borderRadius = AppDimensions.radiusLarge,
    this.isSelected = false,
    this.border,
    this.elevation = 2.0,
  });

  @override
  State<KidCard> createState() => _KidCardState();
}

class _KidCardState extends State<KidCard> {
  double _scale = 1.0;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) {
      setState(() => _scale = 0.96);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      setState(() => _scale = 1.0);
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _scale = 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    // Xử lý viền nổi bật khi được chọn (selected state)
    final effectiveBorder = widget.border ??
        (widget.isSelected
            ? Border.all(color: AppColors.primary, width: 2.5)
            : null);

    final card = AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: Material(
        color: widget.color,
        elevation: widget.isSelected ? widget.elevation + 2 : widget.elevation,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: effectiveBorder,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: widget.onTap != null
                ? () {
                    HapticFeedback.selectionClick();
                    widget.onTap!();
                  }
                : null,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppDimensions.minTouchSize,
                minHeight: AppDimensions.minTouchSize,
              ),
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.semanticLabel == null) return card;

    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      selected: widget.isSelected,
      child: card,
    );
  }
}
