import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';
import '../../domain/enums.dart';

/// Thẻ chọn mục tiêu (dùng ở Onboarding và Hồ sơ).
class GoalOptionTile extends StatelessWidget {
  const GoalOptionTile({
    super.key,
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  final Goal goal;
  final bool selected;
  final VoidCallback onTap;

  static IconData iconOf(Goal goal) => switch (goal) {
        Goal.weightLoss => Icons.monitor_weight_outlined,
        Goal.balanced => Icons.balance_outlined,
        Goal.lessSugar => Icons.icecream_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: selected ? scheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(iconOf(goal), color: scheme.primary),
        title: Text(AppStrings.goal(goal), style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(AppStrings.goalDescription(goal)),
        trailing: selected ? Icon(Icons.check_circle, color: scheme.primary) : null,
      ),
    );
  }
}
