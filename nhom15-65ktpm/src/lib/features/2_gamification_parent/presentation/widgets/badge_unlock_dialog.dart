import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/entities/badge_item.dart';

class BadgeUnlockDialog extends StatelessWidget {
  final List<BadgeItem> badges;

  const BadgeUnlockDialog({super.key, required this.badges});

  static void show(BuildContext context, List<BadgeItem> badges) {
    if (badges.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BadgeUnlockDialog(badges: badges),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstBadge = badges.first;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF8E1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉 CHÚC MỪNG BÉ! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.accentOrange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bé đã xuất sắc mở khóa huy hiệu mới!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentYellow.withValues(alpha: 0.35),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentYellow.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  firstBadge.icon,
                  style: const TextStyle(fontSize: 54),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              firstBadge.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              firstBadge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Bé Tuyệt Vời Quá! 🌟',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
