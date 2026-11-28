import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Thanh chuyển chế độ kiểu Cupertino Segmented Control giống thiết kế Stitch.
class AppSegmentedControl extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.surfaceContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  segments[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.onSurface : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
