import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_inset_card.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../utils/momo_deeplink_helper.dart';

/// Card hiển thị tiến độ tích lũy Quỹ nhóm theo thời gian thực và hiệu ứng chúc mừng khi đạt 100%.
class FundProgressCard extends StatelessWidget {
  const FundProgressCard({
    super.key,
    required this.collectedAmount,
    required this.targetAmount,
    required this.memberCount,
    required this.cycleLabel,
    required this.installmentText,
    required this.onDepositPressed,
    this.nextDepositText,
  });

  final double collectedAmount;
  final double targetAmount;
  final int memberCount;
  final String cycleLabel;
  final String installmentText;
  final VoidCallback onDepositPressed;
  final String? nextDepositText;

  @override
  Widget build(BuildContext context) {
    final double progress =
        targetAmount > 0 ? (collectedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
    final int percent = (progress * 100).round();
    final bool isCompleted = targetAmount > 0 && collectedAmount >= targetAmount;

    return AppInsetCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      borderColor: isCompleted ? AppColors.mint : AppColors.outlineVariantSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiến độ Quỹ tích lũy',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (isCompleted)
                const AppStatusBadge(
                  label: 'Hoàn thành 100% 🎉',
                  tone: AppBadgeTone.mint,
                  icon: Icons.celebration,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mintContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$percent%',
                    style: AppTheme.monoAmount(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onMintContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            MoMoDeeplinkHelper.formatVnd(collectedAmount.round()),
            style: AppTheme.monoAmount(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            'Mục tiêu: ${MoMoDeeplinkHelper.formatVnd(targetAmount.round())} • $memberCount thành viên',
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation(AppColors.mint),
            ),
          ),
          if (isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.mintContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.onMintContainer, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quỹ nhóm đã đạt 100% mục tiêu! Cả nhóm sẵn sàng lên đường thôi!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onMintContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.outlineVariantSoft),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cycleLabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      installmentText,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (nextDepositText != null && nextDepositText!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_available_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              nextDepositText!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: onDepositPressed,
                icon: const Icon(Icons.upload_file, size: 17),
                label: const Text('Nộp biên lai'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
