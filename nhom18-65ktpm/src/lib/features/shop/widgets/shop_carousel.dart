import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../models/shop.dart';
import 'shop_card_item.dart';

/// Danh sách vuốt ngang hiển thị các thẻ tiệm sửa xe / cây xăng phía dưới bản đồ (UC-03).
class ShopCarousel extends StatelessWidget {
  const ShopCarousel({
    super.key,
    required this.shops,
    this.selectedShopId,
    required this.onShopSelected,
    required this.onCall,
    required this.onNavigate,
    this.onExpandRadius,
  });

  final List<Shop> shops;
  final String? selectedShopId;
  final ValueChanged<Shop> onShopSelected;
  final ValueChanged<Shop> onCall;
  final ValueChanged<Shop> onNavigate;
  final VoidCallback? onExpandRadius;

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.motoOrange.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 26,
                color: AppColors.motoOrange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Không tìm thấy địa điểm nào quanh bạn trong bán kính này.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            if (onExpandRadius != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: onExpandRadius,
                icon: const Icon(Icons.zoom_out_map_rounded, size: 17),
                label: const Text('Mở rộng bán kính tìm kiếm'),
              ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 152,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: shops.length,
        itemBuilder: (context, index) {
          final shop = shops[index];
          final isSelected = shop.id == selectedShopId;
          return ShopCardItem(
            shop: shop,
            isSelected: isSelected,
            onTap: () => onShopSelected(shop),
            onCall: () => onCall(shop),
            onNavigate: () => onNavigate(shop),
          );
        },
      ),
    );
  }
}
