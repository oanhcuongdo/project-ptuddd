import 'package:flutter/material.dart';

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 36, color: Colors.orange),
            const SizedBox(height: 6),
            const Text(
              'Không tìm thấy địa điểm nào quanh bạn trong bán kính này.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (onExpandRadius != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onExpandRadius,
                icon: const Icon(Icons.zoom_out_map, size: 16),
                label: const Text('Mở rộng bán kính tìm kiếm'),
              ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 145,
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
