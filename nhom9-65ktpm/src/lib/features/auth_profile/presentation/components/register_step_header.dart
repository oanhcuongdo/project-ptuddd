import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Thanh đầu trang cho luồng Đăng ký 2 bước: nút '<' + badge 'Bước 1 / 2' hoặc 'Bước 2 / 2'
class RegisterStepHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const RegisterStepHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 2,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Quay lại',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Bước $currentStep / $totalSteps',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        if (currentStep == 2) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 5,
              width: double.infinity,
              color: AppColors.divider,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.streakOrange],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
