import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class KidButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String? label;
  final String? semanticLabel;
  final IconData? icon;
  final Color backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isSelected;

  const KidButton({
    super.key,
    required this.onPressed,
    this.label,
    this.semanticLabel,
    this.icon,
    this.backgroundColor = AppColors.buttonPrimary,
    this.textColor,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.isSelected = false,
  })  : assert(label != null || icon != null),
        assert(label != null || semanticLabel != null);

  @override
  State<KidButton> createState() => _KidButtonState();
}

class _KidButtonState extends State<KidButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppDimensions.radiusMedium);
    final height = widget.height < AppDimensions.minTouchSize
        ? AppDimensions.minTouchSize
        : widget.height;
    final width = widget.width == null
        ? null
        : widget.width! < AppDimensions.minTouchSize
            ? AppDimensions.minTouchSize
            : widget.width;
    final foregroundColor = widget.textColor ??
        (widget.backgroundColor == AppColors.primary
            ? AppColors.onPrimary
            : widget.backgroundColor == AppColors.secondary
                ? AppColors.onSecondary
                : widget.backgroundColor == AppColors.accentPurple
                    ? AppColors.onAccentPurple
                    : widget.backgroundColor.computeLuminance() > 0.179
                        ? AppColors.textDark
                        : Colors.white);
    final borderColor = widget.isSelected
        ? AppColors.textDark
        : _outlineColor(widget.backgroundColor);
    final borderWidth = widget.isSelected ? 2.5 : 1.25;
    final horizontalPadding = widget.label == null ? 0.0 : 20.0;

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      button: true,
      selected: widget.isSelected,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: Material(
          color: widget.backgroundColor,
          elevation: widget.isSelected ? 3 : 1.5,
          borderRadius: borderRadius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: widget.isSelected
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.textDark.withValues(alpha: 0.08),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onPressed();
              },
              onTapDown: (_) => setState(() => _scale = 0.94),
              onTapUp: (_) => setState(() => _scale = 1.0),
              onTapCancel: () => setState(() => _scale = 1.0),
              borderRadius: borderRadius,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.minTouchSize,
                  minHeight: AppDimensions.minTouchSize,
                ),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Center(
                      child: AnimatedScale(
                        scale: _scale,
                        duration: const Duration(milliseconds: 100),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null)
                              Icon(
                                widget.icon,
                                color: foregroundColor,
                                size: 28,
                              ),
                            if (widget.icon != null && widget.label != null)
                              const SizedBox(width: 8),
                            if (widget.label != null)
                              Flexible(
                                child: Text(
                                  widget.label!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: foregroundColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _outlineColor(Color backgroundColor) {
    if (backgroundColor == AppColors.buttonPrimary) {
      return AppColors.buttonPrimaryOutline;
    }
    if (backgroundColor == AppColors.buttonSecondary) {
      return AppColors.buttonSecondaryOutline;
    }
    if (backgroundColor == AppColors.buttonPurple) {
      return AppColors.buttonPurpleOutline;
    }
    if (backgroundColor == AppColors.buttonMint) {
      return AppColors.buttonMintOutline;
    }
    if (backgroundColor == AppColors.buttonNeutral) {
      return AppColors.buttonNeutralOutline;
    }
    if (backgroundColor == AppColors.secondary) {
      return AppColors.secondaryOutline;
    }
    return AppColors.textDark.withValues(alpha: 0.35);
  }
}
