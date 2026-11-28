import 'package:flutter/material.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/strings/diary_strings.dart';
import '../../../core/theme/level_colors.dart';
import '../../../domain/enums.dart';
import '../../widgets/disclaimer_note.dart';
import '../../widgets/level_selector.dart';
import '../../widgets/tip_card.dart';
import 'review_controller.dart';

/// Thẻ một món trên màn hình xác nhận: sửa tên, loại, mức độ; xem gợi ý.
/// Món AI không chắc chắn (confidence = low) có viền vàng + "Vui lòng kiểm tra lại".
class FoodItemCard extends StatefulWidget {
  const FoodItemCard({super.key, required this.entry, required this.controller});

  final EditableItem entry;
  final ReviewController controller;

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.entry.item.name);

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;
    final controller = widget.controller;
    final item = entry.item;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: entry.needsReview ? LevelColors.reviewBorder : theme.colorScheme.outlineVariant,
          width: entry.needsReview ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: entry.selected,
                  onChanged: (v) => controller.toggleSelected(entry, v ?? false),
                ),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    enabled: entry.selected,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: ReviewStrings.dishName,
                      hintText: ReviewStrings.dishNameHint,
                      isDense: true,
                    ),
                    onChanged: (v) => controller.rename(entry, v),
                  ),
                ),
                if (entry.removable)
                  IconButton(
                    tooltip: ReviewStrings.removeItem,
                    icon: const Icon(Icons.close),
                    onPressed: () => controller.remove(entry),
                  ),
              ],
            ),
            if (entry.needsReview)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 18, color: LevelColors.reviewBorder),
                    const SizedBox(width: 6),
                    Text(
                      ReviewStrings.checkAgain,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: entry.selected ? 1 : 0.4,
              child: IgnorePointer(
                ignoring: !entry.selected,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.shortNote.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${ReviewStrings.aiNote}: ${item.shortNote}',
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(ReviewStrings.category, style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final category in FoodCategory.values)
                            ChoiceChip(
                              label: Text(AppStrings.category(category)),
                              selected: item.category == category,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => controller.setCategory(entry, category),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(ReviewStrings.levels, style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      for (final attribute in LevelAttribute.values)
                        LevelSelector(
                          attribute: attribute,
                          value: item.levels.of(attribute),
                          onChanged: (level) => controller.setLevel(entry, attribute, level),
                        ),
                      if (item.tips.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(ReviewStrings.tips, style: theme.textTheme.labelLarge),
                        for (final tip in item.tips) TipCard(tip: tip),
                        const SizedBox(height: 8),
                        const DisclaimerNote(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
