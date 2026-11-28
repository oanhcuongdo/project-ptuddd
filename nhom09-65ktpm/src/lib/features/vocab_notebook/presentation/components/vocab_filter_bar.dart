import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/vocab_filter.dart';
import '../styles/vocab_styles.dart';

/// Thanh tìm kiếm từ khóa, lọc trạng thái thuộc từ, lọc ngôn ngữ và sắp xếp cho Sổ tay Từ vựng.
class VocabFilterBar extends StatefulWidget {
  final VocabFilter filter;
  final int resultCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<VocabMasteryFilter> onMasteryChanged;
  final ValueChanged<VocabSortOrder> onSortChanged;
  final VoidCallback onReset;

  const VocabFilterBar({
    super.key,
    required this.filter,
    required this.resultCount,
    required this.onSearchChanged,
    required this.onLanguageChanged,
    required this.onMasteryChanged,
    required this.onSortChanged,
    required this.onReset,
  });

  @override
  State<VocabFilterBar> createState() => _VocabFilterBarState();
}

class _VocabFilterBarState extends State<VocabFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filter.searchQuery);
  }

  @override
  void didUpdateWidget(covariant VocabFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.searchQuery != _searchController.text) {
      _searchController.text = widget.filter.searchQuery;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: VocabStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  cursorColor: VocabStyles.tealPrimary,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  onChanged: widget.onSearchChanged,
                  decoration: VocabStyles.inputDecoration(
                    hintText: 'Tìm từ vựng, nghĩa hoặc câu ví dụ...',
                    prefixIcon: Icons.search_rounded,
                    suffixIcon: widget.filter.searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchChanged('');
                            },
                            tooltip: 'Xóa từ khóa',
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<VocabSortOrder>(
                    value: widget.filter.sortOrder,
                    isDense: true,
                    dropdownColor: Colors.white,
                    iconEnabledColor: VocabStyles.tealDark,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(
                      Icons.sort_rounded,
                      size: 18,
                      color: VocabStyles.tealDark,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    items: VocabSortOrder.values
                        .map(
                          (order) => DropdownMenuItem(
                            value: order,
                            child: Text(order.label),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) widget.onSortChanged(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...VocabMasteryFilter.values.map((m) {
                final selected = widget.filter.masteryFilter == m;
                return _FilterPill(
                  label: m.label,
                  selected: selected,
                  onTap: () => widget.onMasteryChanged(m),
                );
              }),
              const SizedBox(
                height: 18,
                child: VerticalDivider(width: 10, color: AppColors.divider),
              ),
              _FilterPill(
                label: 'Mọi ngôn ngữ',
                selected: widget.filter.languageCode == null,
                onTap: () => widget.onLanguageChanged(null),
              ),
              _FilterPill(
                label: '🇬🇧 Tiếng Anh',
                selected: widget.filter.languageCode == 'en',
                onTap: () => widget.onLanguageChanged('en'),
              ),
              _FilterPill(
                label: '🇨🇳 Tiếng Trung',
                selected: widget.filter.languageCode == 'zh-cn',
                onTap: () => widget.onLanguageChanged('zh-cn'),
              ),
              _FilterPill(
                label: '🇻🇳 Tiếng Việt',
                selected: widget.filter.languageCode == 'vi',
                onTap: () => widget.onLanguageChanged('vi'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Hiển thị ${widget.resultCount} từ vựng',
                style: VocabStyles.metaText,
              ),
              const Spacer(),
              if (widget.filter.hasActiveFilter)
                TextButton.icon(
                  onPressed: widget.onReset,
                  style: TextButton.styleFrom(
                    foregroundColor: VocabStyles.tealDark,
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 15),
                  label: const Text(
                    'Đặt lại bộ lọc',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? VocabStyles.tealPillBg : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? VocabStyles.tealPrimary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? VocabStyles.tealDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
