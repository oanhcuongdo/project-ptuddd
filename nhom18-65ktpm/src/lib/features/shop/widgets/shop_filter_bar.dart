import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../shop_filter.dart';

/// Bộ lọc tìm kiếm, bán kính và sắp xếp tiệm sửa xe & cây xăng (UC-03).
class ShopFilterBar extends StatefulWidget {
  const ShopFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    required this.selectedRadiusMeters,
    required this.isOpenOnly,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onRadiusChanged,
    required this.onOpenOnlyChanged,
    this.selectedSort = ShopSort.nearest,
    this.onSortChanged,
  });

  final String searchQuery;
  final String? selectedCategory; // null = Tất cả, 'repair_shop', 'gas_station'
  final int selectedRadiusMeters;
  final bool isOpenOnly;
  final ShopSort selectedSort;

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<int> onRadiusChanged;
  final ValueChanged<bool> onOpenOnlyChanged;
  final ValueChanged<ShopSort>? onSortChanged;

  @override
  State<ShopFilterBar> createState() => _ShopFilterBarState();
}

class _ShopFilterBarState extends State<ShopFilterBar> {
  late final _controller = TextEditingController(text: widget.searchQuery);

  @override
  void didUpdateWidget(ShopFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ô tìm kiếm theo tên tiệm, chủ tiệm hoặc đường
          TextField(
            controller: _controller,
            onChanged: widget.onSearchChanged,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceMuted,
              hintText: 'Tìm tên tiệm, chủ tiệm, tên đường...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.inkMuted,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              suffixIcon: widget.searchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _controller.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Hàng lọc danh mục, bán kính, trạng thái mở cửa & sắp xếp
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(
                  label: 'Tất cả',
                  category: null,
                  icon: Icons.apps_rounded,
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  label: 'Tiệm sửa xe',
                  category: 'repair_shop',
                  icon: Icons.build_rounded,
                  activeColor: AppColors.motoOrange,
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  label: 'Cây xăng',
                  category: 'gas_station',
                  icon: Icons.local_gas_station_rounded,
                  activeColor: AppColors.primaryLight,
                ),
                const SizedBox(width: 8),
                Container(height: 18, width: 1, color: AppColors.border),
                const SizedBox(width: 8),
                // Bán kính
                ...[1000, 3000, 5000, 10000].map((radius) {
                  final isSelected = widget.selectedRadiusMeters == radius;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        '${radius ~/ 1000} km',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.navyBrand
                              : AppColors.inkSecondary,
                        ),
                      ),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (_) => widget.onRadiusChanged(radius),
                      selectedColor: AppColors.infoBg,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
                const SizedBox(width: 4),
                // Lọc chỉ hiển thị tiệm đang mở
                FilterChip(
                  avatar: Icon(
                    Icons.access_time_filled_rounded,
                    size: 15,
                    color: widget.isOpenOnly ? Colors.white : AppColors.success,
                  ),
                  label: Text(
                    'Đang mở',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isOpenOnly
                          ? Colors.white
                          : AppColors.inkPrimary,
                      fontWeight: widget.isOpenOnly
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  selected: widget.isOpenOnly,
                  selectedColor: AppColors.success,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: widget.isOpenOnly
                        ? AppColors.success
                        : AppColors.border,
                  ),
                  onSelected: widget.onOpenOnlyChanged,
                  visualDensity: VisualDensity.compact,
                ),
                if (widget.onSortChanged != null) ...[
                  const SizedBox(width: 8),
                  Container(height: 18, width: 1, color: AppColors.border),
                  const SizedBox(width: 8),
                  _buildSortChip(
                    label: 'Gần nhất',
                    sort: ShopSort.nearest,
                    icon: Icons.near_me_rounded,
                  ),
                  const SizedBox(width: 6),
                  _buildSortChip(
                    label: 'Đánh giá cao',
                    sort: ShopSort.highestRated,
                    icon: Icons.star_rounded,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required String? category,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = widget.selectedCategory == category;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 15,
        color: isSelected ? Colors.white : activeColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : AppColors.inkPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => widget.onCategoryChanged(category),
      selectedColor: activeColor,
      side: BorderSide(color: isSelected ? activeColor : AppColors.border),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSortChip({
    required String label,
    required ShopSort sort,
    required IconData icon,
  }) {
    final isSelected = widget.selectedSort == sort;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 15,
        color: isSelected ? Colors.white : const Color(0xFFD97706),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : AppColors.inkPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => widget.onSortChanged?.call(sort),
      selectedColor: AppColors.navyBrand,
      side: BorderSide(
        color: isSelected ? AppColors.navyBrand : AppColors.border,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
