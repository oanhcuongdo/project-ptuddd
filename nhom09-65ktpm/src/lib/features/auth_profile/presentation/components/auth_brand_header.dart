import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../styles/auth_styles.dart';

/// Component Header thương hiệu BuddyTalk:
/// Logo bo tròn gradient + badge Streak + tên 2 màu BuddyTalk + khẩu hiệu
class AuthBrandHeader extends StatelessWidget {
  final String tagline;

  const AuthBrandHeader({super.key, required this.tagline});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(
          height: 98,
          width: 120,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: AuthStyles.brandIconBox,
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.streakGold,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 2,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: AuthStyles.streakBadge,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.streakOrange,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Streak',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Buddy',
                style: AuthStyles.brandDark.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const TextSpan(
                text: 'Talk',
                style: AuthStyles.brandAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tagline,
          textAlign: TextAlign.center,
          style: AuthStyles.tagline.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
