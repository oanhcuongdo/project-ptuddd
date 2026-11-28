import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class KidProgressBar extends StatelessWidget {
  final double value;
  final String semanticLabel;
  final Color? color;
  final Color? trackColor;
  final double height;

  const KidProgressBar({
    super.key,
    required this.value,
    required this.semanticLabel,
    this.color,
    this.trackColor,
    this.height = 12,
  })  : assert(value >= 0 && value <= 1),
        assert(height > 0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progressColor = color ?? scheme.primary;

    return Semantics(
      label: semanticLabel,
      value: '${(value * 100).round()}%',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            color: progressColor,
            backgroundColor:
                trackColor ?? AppColors.surface.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
