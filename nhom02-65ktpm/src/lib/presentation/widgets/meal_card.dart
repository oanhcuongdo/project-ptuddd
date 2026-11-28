import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';
import '../../domain/entities/meal.dart';
import '../../domain/enums.dart';
import '../utils/formatters.dart';
import 'level_chip.dart';

/// Thẻ tóm tắt một bữa ăn trong nhật ký.
class MealCard extends StatelessWidget {
  const MealCard({super.key, required this.meal, this.onTap, this.showDate = false});

  final Meal meal;
  final VoidCallback? onTap;

  /// Hiện cả ngày (dùng ở Thùng rác / Trang chủ).
  final bool showDate;

  static IconData mealTypeIcon(MealType type) => switch (type) {
        MealType.breakfast => Icons.free_breakfast_outlined,
        MealType.lunch => Icons.lunch_dining_outlined,
        MealType.dinner => Icons.dinner_dining_outlined,
        MealType.snack => Icons.cookie_outlined,
      };

  static IconData inputMethodIcon(InputMethod method) => switch (method) {
        InputMethod.photo => Icons.photo_camera_outlined,
        InputMethod.menu => Icons.restaurant_menu,
        InputMethod.manual => Icons.edit_note,
        InputMethod.relog => Icons.replay,
      };

  /// Mức "nổi bật nhất" của một thuộc tính trong cả bữa (lấy mức cao nhất).
  Level _maxLevel(LevelAttribute attribute) {
    var result = Level.low;
    for (final item in meal.items) {
      final level = item.levels.of(attribute);
      if (level.index > result.index) result = level;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final names = meal.items.map((i) => i.name).join(', ');
    final when = showDate ? Formatters.dateTime(meal.eatenAt) : Formatters.time(meal.eatenAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(mealTypeIcon(meal.mealType), color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      names,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppStrings.mealType(meal.mealType)} • $when',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final attribute in const [
                          LevelAttribute.sugar,
                          LevelAttribute.fat,
                          LevelAttribute.veg,
                        ])
                          LevelChip(attribute: attribute, level: _maxLevel(attribute), compact: true),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(inputMethodIcon(meal.inputMethod),
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
