import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../styles/auth_styles.dart';

/// Cột giới thiệu bên trái cho giao diện Chrome / Desktop 
class AuthWebHero extends StatelessWidget {
  final String tagline;

  const AuthWebHero({super.key, required this.tagline});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 98,
          width: 112,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topLeft,
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
                right: 0,
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
        const SizedBox(height: AppSpacing.lg),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Buddy',
                style: AuthStyles.heroBrandDark.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const TextSpan(
                text: 'Talk',
                style: AuthStyles.heroBrandAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          tagline,
          style: AuthStyles.heroSubtitle.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _HeroFeatureRow(
          icon: Icons.local_fire_department_rounded,
          text: 'Duy trì chuỗi kỷ luật (Streak) và Ma trận nhiệt mỗi ngày',
        ),
        const SizedBox(height: AppSpacing.md),
        const _HeroFeatureRow(
          icon: Icons.groups_rounded,
          text: 'Ghép cặp bạn đồng hành & phòng học nhóm nhiều người',
        ),
        const SizedBox(height: AppSpacing.md),
        const _HeroFeatureRow(
          icon: Icons.translate_rounded,
          text: 'Trò chuyện Realtime tích hợp dịch tức thì song ngữ',
        ),
      ],
    );
  }
}

class _HeroFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroFeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 19),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.5,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
