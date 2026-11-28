import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/hci_components.dart';
import '../../../models/shop.dart';
import '../../navigation/navigation_helper.dart';

/// Thẻ thông tin tóm tắt tiệm sửa xe / cây xăng trong danh sách vuốt ngang (UC-03).
class ShopCardItem extends StatelessWidget {
  const ShopCardItem({
    super.key,
    required this.shop,
    this.isSelected = false,
    this.onTap,
    this.onCall,
    this.onNavigate,
  });

  final Shop shop;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final isRepair = shop.category == 'repair_shop';
    final accent = isRepair ? AppColors.motoOrange : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 316,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : AppColors.navyDeep.withValues(alpha: 0.09),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Dòng trên: Biểu tượng thể loại, tên tiệm & địa chỉ
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: accent.withValues(alpha: 0.22)),
                  ),
                  child: Icon(
                    isRepair
                        ? Icons.build_rounded
                        : Icons.local_gas_station_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppColors.inkPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shop.address,
                        style: const TextStyle(
                          color: AppColors.inkSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Dòng giữa: Khoảng cách, trạng thái Mở/Đóng & điểm đánh giá
            Row(
              children: [
                if (shop.distanceM != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      NavigationHelper.formatDistance(shop.distanceM!),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyBrand,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: shop.isOpen ? AppColors.successBg : AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LiveStatusDot(
                        color: shop.isOpen ? AppColors.success : AppColors.sosRed,
                        size: 6,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shop.isOpen ? 'Mở cửa' : 'Đóng cửa',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: shop.isOpen
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        shop.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Dòng dưới: 2 nút thao tác nhanh (Fitts's Law: rộng & tách biệt rõ)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(
                        color: AppColors.success.withValues(alpha: 0.45),
                      ),
                      foregroundColor: const Color(0xFF047857),
                      backgroundColor: AppColors.successBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onCall,
                    icon: const Icon(Icons.phone_rounded, size: 15),
                    label: const Text(
                      'Gọi ngay',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation_rounded, size: 15),
                    label: const Text(
                      'Chỉ đường',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
