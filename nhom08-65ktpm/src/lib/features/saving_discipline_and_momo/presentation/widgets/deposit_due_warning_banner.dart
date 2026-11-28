import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/saving_plan.dart';
import '../../utils/momo_deeplink_helper.dart';
import '../../utils/saving_streak_calculator.dart';

/// Warning banner alerting the user when their saving term requires a deposit today or is overdue.
class DepositDueWarningBanner extends StatelessWidget {
  const DepositDueWarningBanner({
    super.key,
    required this.reminder,
    this.onDepositTap,
  });

  final TodayDepositReminder reminder;
  final VoidCallback? onDepositTap;

  @override
  Widget build(BuildContext context) {
    if (!reminder.shouldWarn) return const SizedBox.shrink();

    final isOverdue = reminder.urgency == DepositReminderUrgency.overdue;
    final bgColor = isOverdue ? AppColors.errorContainer : AppColors.amberContainer;
    final borderColor = isOverdue ? AppColors.error : AppColors.amber;
    final fgColor = isOverdue ? AppColors.onErrorContainer : AppColors.onAmberContainer;
    final icon = isOverdue ? Icons.warning_amber_rounded : Icons.notifications_active_outlined;

    final freqLabel = switch (reminder.frequency) {
      SavingFrequency.daily => 'Hàng ngày',
      SavingFrequency.weekly => 'Hàng tuần',
      SavingFrequency.monthly => 'Hàng tháng',
    };

    final title = isOverdue
        ? (reminder.overdueTermCount > 1
            ? 'Quá hạn ${reminder.overdueTermCount} kỳ đóng quỹ ($freqLabel)'
            : 'Bạn đang trễ hạn đóng quỹ ($freqLabel)')
        : (reminder.frequency == SavingFrequency.daily
            ? 'Hôm nay cần nạp quỹ ($freqLabel)'
            : 'Hôm nay là hạn đóng quỹ ($freqLabel)');

    final dueDate = reminder.dueDate;
    final dueText = dueDate == null
        ? 'hôm nay'
        : '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}';
    final amountText = reminder.amountDue > 0
        ? '${MoMoDeeplinkHelper.formatVnd(reminder.amountDue.round())} • '
        : '';
    final termText = reminder.installmentIndex != null
        ? 'Kỳ ${reminder.installmentIndex} • '
        : '';

    final subtitle = isOverdue
        ? '${termText}Hạn $dueText • ${amountText}Hãy nộp bù ngay hôm nay để giữ kỷ luật quỹ.'
        : (reminder.frequency == SavingFrequency.daily
            ? '$termText${amountText}Nạp trong hôm nay để giữ chuỗi đúng hạn.'
            : '$termText${amountText}Hạn chót hôm nay ($dueText), nộp biên lai ngay nhé!');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: fgColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: fgColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (onDepositTap != null) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onDepositTap,
              style: FilledButton.styleFrom(
                backgroundColor: borderColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Nộp ngay',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
