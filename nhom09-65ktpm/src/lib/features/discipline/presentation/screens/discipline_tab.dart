import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth_profile/presentation/providers/auth_provider.dart';

/// Tab Kỷ luật cá nhân — đọc dữ liệu thật từ hồ sơ Supabase (không fix cứng số liệu giả)
class DisciplineTab extends StatelessWidget {
  const DisciplineTab({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().currentProfile;
    final streak = profile?.streakCount ?? 0;
    final goalMinutes = profile?.dailyGoalMinutes ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppColors.streakBg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 48,
                    color: AppColors.streakOrange,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chuỗi Kỷ Luật (Streak)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$streak ngày liên tiếp • Mục tiêu $goalMinutes phút/ngày',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Mục tiêu hôm nay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'Chưa có mục tiêu nào. Dữ liệu sẽ được tải trực tiếp từ bảng daily_goals trên Supabase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
