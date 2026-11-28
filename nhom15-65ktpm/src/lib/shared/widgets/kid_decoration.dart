import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum KidDecorationType { star, heart, sun, flower }

class KidDecoration extends StatelessWidget {
  final KidDecorationType type;
  final double size;
  final double rotation;

  const KidDecoration({
    super.key,
    required this.type,
    this.size = AppDimensions.iconSizeLarge,
    this.rotation = 0,
  }) : assert(size > 0);

  IconData get _icon {
    switch (type) {
      case KidDecorationType.star:
        return Icons.star_rounded;
      case KidDecorationType.heart:
        return Icons.favorite_rounded;
      case KidDecorationType.sun:
        return Icons.wb_sunny_rounded;
      case KidDecorationType.flower:
        return Icons.local_florist_rounded;
    }
  }

  Color get _color {
    switch (type) {
      case KidDecorationType.star:
        return AppColors.secondary;
      case KidDecorationType.heart:
        return AppColors.primary;
      case KidDecorationType.sun:
        return AppColors.warning;
      case KidDecorationType.flower:
        return AppColors.accentPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: _color.withValues(alpha: 0.28)),
            ),
            child: Icon(
              _icon,
              size: size * 0.58,
              color: _color,
            ),
          ),
        ),
      ),
    );
  }
}
