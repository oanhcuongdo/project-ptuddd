import 'package:flutter/material.dart';

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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 310,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E88E5) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF1E88E5).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Dòng trên: Icon thể loại, tên, badge mở/đóng
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      isRepair ? Colors.orange[100] : Colors.blue[100],
                  child: Icon(
                    isRepair ? Icons.build : Icons.local_gas_station,
                    color: isRepair ? Colors.orange[800] : Colors.blue[800],
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
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shop.address,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Dòng giữa: Khoảng cách, Rating, Giờ mở cửa
            Row(
              children: [
                if (shop.distanceM != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      NavigationHelper.formatDistance(shop.distanceM!),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: shop.isOpen ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    shop.isOpen ? 'Mở cửa' : 'Đóng cửa',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: shop.isOpen ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.star, size: 15, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  shop.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // Dòng dưới: 2 nút hành động nhanh
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: Colors.green[400]!),
                      foregroundColor: Colors.green[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onCall,
                    icon: const Icon(Icons.phone, size: 14),
                    label: const Text('Gọi ngay', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation, size: 14),
                    label: const Text('Chỉ đường', style: TextStyle(fontSize: 12)),
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
