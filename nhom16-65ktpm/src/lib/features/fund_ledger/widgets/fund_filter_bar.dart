import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/fund_transaction_model.dart';

/// Widget thanh tìm kiếm và bộ lọc giao dịch (FundFilterBar)
/// Hỗ trợ tìm kiếm từ khóa realtime, lọc theo Thu/Chi và lọc theo danh mục
class FundFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final TransactionType? selectedType;
  final String? selectedCategory;
  final List<String> categories;
  final ValueChanged<TransactionType?> onTypeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback? onClearSearch;

  const FundFilterBar({
    super.key,
    required this.searchController,
    required this.selectedType,
    required this.selectedCategory,
    required this.categories,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Ô tìm kiếm từ khoá
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm giao dịch, nhà hảo tâm, người nhận...',
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: onClearSearch ?? () => searchController.clear(),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 2. Hàng lọc Loại Thu / Chi và Danh mục
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Tất cả',
                isSelected: selectedType == null,
                onTap: () => onTypeChanged(null),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Khoản Thu (+)',
                icon: Icons.south_west_rounded,
                selectedColor: AppColors.success,
                isSelected: selectedType == TransactionType.thu,
                onTap: () => onTypeChanged(TransactionType.thu),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Khoản Chi (-)',
                icon: Icons.north_east_rounded,
                selectedColor: AppColors.danger,
                isSelected: selectedType == TransactionType.chi,
                onTap: () => onTypeChanged(TransactionType.chi),
              ),

              // Dropdown lọc theo danh mục
              if (categories.isNotEmpty) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedCategory != null && selectedCategory != 'Tất cả'
                          ? AppColors.primary
                          : Colors.grey.withValues(alpha: 0.25),
                      width: selectedCategory != null && selectedCategory != 'Tất cả' ? 1.5 : 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory ?? 'Tất cả',
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selectedCategory != null && selectedCategory != 'Tất cả'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: selectedCategory != null && selectedCategory != 'Tất cả'
                            ? AppColors.primaryDark
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: onCategoryChanged,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    Color? selectedColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = selectedColor ?? AppColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
