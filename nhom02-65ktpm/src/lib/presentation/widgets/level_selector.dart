import 'package:flutter/material.dart';

import '../../core/strings/app_strings.dart';
import '../../core/theme/level_colors.dart';
import '../../domain/enums.dart';

/// Chọn mức độ của một thuộc tính bằng 3 chip (thấp / vừa / cao...).
class LevelSelector extends StatelessWidget {
  const LevelSelector({
    super.key,
    required this.attribute,
    required this.value,
    required this.onChanged,
  });

  final LevelAttribute attribute;
  final Level value;
  final ValueChanged<Level> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              AppStrings.attribute(attribute),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: [
                for (final level in Level.values)
                  _buildChip(level, brightness),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(Level level, Brightness brightness) {
    final selected = level == value;
    final colors = LevelColors.colorsOf(LevelColors.toneOf(attribute, level), brightness);
    return ChoiceChip(
      label: Text(AppStrings.level(attribute, level)),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      selectedColor: colors.background,
      labelStyle: TextStyle(
        color: selected ? colors.foreground : null,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
      ),
      onSelected: (_) => onChanged(level),
    );
  }
}
