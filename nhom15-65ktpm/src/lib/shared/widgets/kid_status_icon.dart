import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum KidStatusType { success, warning, error, info }

class KidStatusIcon extends StatelessWidget {
  final KidStatusType status;
  final String? semanticLabel;
  final double size;

  const KidStatusIcon({
    super.key,
    required this.status,
    this.semanticLabel,
    this.size = AppDimensions.minTouchSize,
  }) : assert(size >= AppDimensions.minTouchSize);

  IconData get _icon {
    switch (status) {
      case KidStatusType.success:
        return Icons.check_rounded;
      case KidStatusType.warning:
        return Icons.priority_high_rounded;
      case KidStatusType.error:
        return Icons.close_rounded;
      case KidStatusType.info:
        return Icons.info_outline_rounded;
    }
  }

  Color get _foregroundColor {
    switch (status) {
      case KidStatusType.success:
        return AppColors.success;
      case KidStatusType.warning:
        return AppColors.onWarning;
      case KidStatusType.error:
        return AppColors.error;
      case KidStatusType.info:
        return AppColors.info;
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case KidStatusType.success:
        return AppColors.success;
      case KidStatusType.warning:
        return AppColors.warning;
      case KidStatusType.error:
        return AppColors.error;
      case KidStatusType.info:
        return AppColors.info;
    }
  }

  String get _defaultLabel {
    switch (status) {
      case KidStatusType.success:
        return 'Thành công';
      case KidStatusType.warning:
        return 'Cần chú ý';
      case KidStatusType.error:
        return 'Có lỗi';
      case KidStatusType.info:
        return 'Thông tin';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? _defaultLabel,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _backgroundColor.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _icon,
            color: _foregroundColor,
            size: size * 0.58,
          ),
        ),
      ),
    );
  }
}
