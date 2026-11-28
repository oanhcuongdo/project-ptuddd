import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/topic_model.dart';
import '../styles/topics_styles.dart';

/// Thanh tìm kiếm song ngữ & bộ lọc cấp độ (A1-B2), danh mục và trạng thái hoàn thành.
class TopicsFilterBar extends StatefulWidget {
  final String selectedLevel;
  final String selectedCategory;
  final String searchQuery;
  final bool showOnlyIncomplete;
  final bool hasActiveFilters;
  final List<String> availableCategories;
  final int Function(String level) countByLevel;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onShowOnlyIncompleteChanged;
  final VoidCallback onResetFilters;

  const TopicsFilterBar({
    super.key,
    required this.selectedLevel,
    required this.selectedCategory,
    required this.searchQuery,
    required this.showOnlyIncomplete,
    required this.hasActiveFilters,
    required this.availableCategories,
    required this.countByLevel,
    required this.onLevelChanged,
    required this.onCategoryChanged,
    required this.onSearchChanged,
    required this.onShowOnlyIncompleteChanged,
    required this.onResetFilters,
  });

  @override
  State<TopicsFilterBar> createState() => _TopicsFilterBarState();
}

class _TopicsFilterBarState extends State<TopicsFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant TopicsFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
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
    final levels = ['ALL', ...TopicModel.supportedLevels];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: TopicsStyles.filterSurfaceDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: levels.map(_buildLevelChip).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildCategoryDropdown(),
              FilterChip(
                selected: widget.showOnlyIncomplete,
                onSelected: widget.onShowOnlyIncompleteChanged,
                label: const Text('Chưa hoàn thành'),
                selectedColor: TopicsStyles.tealPillBg,
                checkmarkColor: TopicsStyles.tealDark,
                side: BorderSide(
                  color: widget.showOnlyIncomplete
                      ? TopicsStyles.tealPrimary
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: widget.showOnlyIncomplete
                      ? TopicsStyles.tealDark
                      : AppColors.textSecondary,
                ),
              ),
              if (widget.hasActiveFilters)
                TextButton.icon(
                  onPressed: widget.onResetFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  label: const Text('Xóa bộ lọc'),
                  style: TextButton.styleFrom(
                    foregroundColor: TopicsStyles.tealDark,
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: widget.onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Tìm chủ đề theo tiếng Việt hoặc tiếng Anh (vd: du lịch, cafe, AI)...',
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: TopicsStyles.tealPrimary,
          size: 20,
        ),
        suffixIcon: widget.searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Xóa từ khóa',
                onPressed: () => widget.onSearchChanged(''),
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            : null,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: TopicsStyles.tealPrimary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLevelChip(String level) {
    final isSelected = widget.selectedLevel == level;
    final style = TopicsStyles.styleForLevel(level);
    final count = widget.countByLevel(level);
    final label = level == 'ALL' ? 'Tất cả ($count)' : '$level ($count)';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: isSelected,
        onSelected: (_) => widget.onLevelChanged(level),
        label: Text(label),
        showCheckmark: false,
        selectedColor: style.background,
        backgroundColor: const Color(0xFFF8FAFC),
        side: BorderSide(
          color: isSelected ? style.foreground : AppColors.divider,
          width: isSelected ? 1.4 : 1,
        ),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? style.foreground : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = widget.availableCategories.isEmpty
        ? const ['ALL']
        : widget.availableCategories;
    final currentValue =
        categories.contains(widget.selectedCategory)
            ? widget.selectedCategory
            : 'ALL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isDense: true,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category == 'ALL' ? 'Tất cả danh mục' : category,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              widget.onCategoryChanged(value);
            }
          },
        ),
      ),
    );
  }
}

