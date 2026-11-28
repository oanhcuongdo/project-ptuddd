import 'package:flutter/material.dart';

/// Bộ lọc tìm kiếm và bán kính tiệm sửa xe & cây xăng (UC-03).
class ShopFilterBar extends StatelessWidget {
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
  });

  final String searchQuery;
  final String? selectedCategory; // null = Tất cả, 'repair_shop', 'gas_station'
  final int selectedRadiusMeters;
  final bool isOpenOnly;

  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<int> onRadiusChanged;
  final ValueChanged<bool> onOpenOnlyChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ô tìm kiếm theo tên hoặc đường
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm tiệm sửa xe, cây xăng, tên đường...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Hàng lọc danh mục & Trạng thái mở cửa
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(
                  label: 'Tất cả',
                  category: null,
                  icon: Icons.apps,
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  label: 'Tiệm sửa xe',
                  category: 'repair_shop',
                  icon: Icons.build,
                ),
                const SizedBox(width: 6),
                _buildCategoryChip(
                  label: 'Cây xăng',
                  category: 'gas_station',
                  icon: Icons.local_gas_station,
                ),
                const SizedBox(width: 8),
                Container(height: 18, width: 1, color: Colors.grey[300]),
                const SizedBox(width: 8),
                // Bán kính
                ...[1000, 3000, 5000, 10000].map((radius) {
                  final isSelected = selectedRadiusMeters == radius;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('${radius ~/ 1000} km', style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (_) => onRadiusChanged(radius),
                      selectedColor: const Color(0xFFE3F2FD),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
                const SizedBox(width: 4),
                // Switch chỉ hiển thị tiệm đang mở
                FilterChip(
                  avatar: Icon(
                    Icons.access_time_filled,
                    size: 16,
                    color: isOpenOnly ? Colors.white : Colors.green[700],
                  ),
                  label: Text(
                    'Đang mở',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOpenOnly ? Colors.white : Colors.black87,
                      fontWeight: isOpenOnly ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isOpenOnly,
                  selectedColor: Colors.green[600],
                  checkmarkColor: Colors.white,
                  onSelected: onOpenOnlyChanged,
                  visualDensity: VisualDensity.compact,
                ),
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
  }) {
    final isSelected = selectedCategory == category;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.blueGrey),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onCategoryChanged(category),
      selectedColor: const Color(0xFF1E88E5),
      visualDensity: VisualDensity.compact,
    );
  }
}
