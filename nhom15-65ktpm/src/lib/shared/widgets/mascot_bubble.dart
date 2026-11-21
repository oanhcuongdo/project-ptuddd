import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class MascotBubbleWidget extends StatelessWidget {
  final String speechText;
  final VoidCallback? onMascotTap;

  const MascotBubbleWidget({
    super.key,
    required this.speechText,
    this.onMascotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          label: 'Linh vật Panda',
          button: true,
          child: GestureDetector(
            onTap: onMascotTap,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentYellow.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🐼', style: TextStyle(fontSize: 48)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchSize,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentPurple,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('✋', style: TextStyle(fontSize: 34)),
                Text('➕', style: TextStyle(fontSize: 34)),
                Text('⚡', style: TextStyle(fontSize: 34)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
