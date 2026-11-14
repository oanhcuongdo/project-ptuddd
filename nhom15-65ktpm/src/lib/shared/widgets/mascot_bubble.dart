import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

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
        // Linh vật gấu trúc Panda dễ thương
        GestureDetector(
          onTap: onMascotTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentYellow,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentYellow.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🐼',
                style: TextStyle(fontSize: 42),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Hộp thoại lời nói
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              speechText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
