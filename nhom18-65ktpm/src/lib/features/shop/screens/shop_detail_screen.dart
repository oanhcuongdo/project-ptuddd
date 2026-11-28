import 'package:flutter/material.dart';

import '../../../models/review.dart';
import '../../../models/shop.dart';
import '../../../repositories/shop_repository.dart';
import '../../call/call_helper.dart';
import '../../navigation/navigation_helper.dart';
import '../../navigation/screens/navigation_screen.dart';
import '../../review/data/supabase_review_repository.dart';
import '../../review/widgets/review_list_item.dart';
import '../../review/widgets/write_review_dialog.dart';

/// Màn hình Chi tiết Tiệm sửa xe & Cây xăng (UC-04).
class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({
    super.key,
    required this.shop,
    this.userLat,
    this.userLng,
  });

  final Shop shop;
  final double? userLat;
  final double? userLng;

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Shop _shop;
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  String? _reviewError;

  @override
  void initState() {
    super.initState();
    _shop = widget.shop;
    _loadReviews();
    _refreshShopData();
  }

  Future<void> _refreshShopData() async {
    try {
      final updated = await ShopRepository().byId(_shop.id);
      if (updated != null && mounted) {
        setState(() => _shop = updated);
      }
    } catch (_) {}
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
      _reviewError = null;
    });

    try {
      final list = await SupabaseReviewRepository().listByShop(_shop.id);
      if (mounted) {
        setState(() {
          _reviews = list;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reviewError = 'Không thể tải danh sách đánh giá';
          _isLoadingReviews = false;
        });
      }
    }
  }

  void _onCall() {
    CallHelper.makeCall(context, _shop.phone);
  }

  void _onNavigate() {
    if (widget.userLat == null || widget.userLng == null) {
      NavigationHelper.openExternalGoogleMaps(
        destinationLat: _shop.latitude,
        destinationLng: _shop.longitude,
        context: context,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          originLat: widget.userLat!,
          originLng: widget.userLng!,
          destinationLat: _shop.latitude,
          destinationLng: _shop.longitude,
          destinationTitle: _shop.name,
          destinationAddress: _shop.address,
        ),
      ),
    );
  }

  void _onSendSos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Yêu cầu Cứu hộ SOS'),
          ],
        ),
        content: Text(
          'Bạn đang gửi yêu cầu cứu hộ khẩn cấp tới "${_shop.name}".\n\n'
          'Sau khi gửi, thông tin sự cố và vị trí GPS của bạn sẽ được chuyển đến chủ tiệm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tín hiệu SOS đã được ghi nhận và gửi đi.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('Xác nhận gửi'),
          ),
        ],
      ),
    );
  }

  void _onWriteReview() {
    showDialog(
      context: context,
      builder: (_) => WriteReviewDialog(
        shopId: _shop.id,
        shopName: _shop.name,
        onSuccess: () {
          _loadReviews();
          _refreshShopData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRepair = _shop.category == 'repair_shop';

    return Scaffold(
      appBar: AppBar(
        title: Text(_shop.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh mặt tiền hoặc placeholder
            _buildShopHeaderImage(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge thể loại và trạng thái
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isRepair ? Colors.orange[100] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isRepair
                                  ? Icons.build
                                  : Icons.local_gas_station,
                              size: 16,
                              color: isRepair
                                  ? Colors.orange[800]
                                  : Colors.blue[800],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isRepair ? 'Tiệm sửa xe máy' : 'Cây xăng',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isRepair
                                    ? Colors.orange[900]
                                    : Colors.blue[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _shop.isOpen ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _shop.isOpen ? 'ĐANG MỞ CỬA' : 'TẠM ĐÓNG CỬA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _shop.isOpen ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            _shop.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            ' (${_shop.reviewCount})',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(
                    _shop.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Thông tin chi tiết
                  _buildInfoRow(
                    icon: Icons.location_on,
                    text: _shop.address,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.access_time,
                    text: 'Giờ mở cửa: ${_shop.openTime} - ${_shop.closeTime}',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.phone,
                    text: 'Hotline: ${_shop.phone}',
                    color: Colors.green,
                  ),

                  if (_shop.distanceM != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.straighten,
                      text:
                          'Khoảng cách: ${NavigationHelper.formatDistance(_shop.distanceM!)}',
                      color: Colors.indigo,
                    ),
                  ],

                  const Divider(height: 32),

                  // 4 Nút hành động nhanh
                  _buildActionButtons(),

                  const Divider(height: 32),

                  // Phần Đánh giá & Nhận xét
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đánh giá & Nhận xét (${_reviews.length})',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _onWriteReview,
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: const Text('Viết đánh giá'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildReviewsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopHeaderImage() {
    if (_shop.imageUrl != null && _shop.imageUrl!.trim().isNotEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          _shop.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    final isRepair = _shop.category == 'repair_shop';
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRepair
              ? [const Color(0xFFF57C00), const Color(0xFFFFB74D)]
              : [const Color(0xFF1976D2), const Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          isRepair ? Icons.build_circle : Icons.local_gas_station,
          size: 72,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _onCall,
                icon: const Icon(Icons.phone),
                label: const Text('Gọi ngay', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _onNavigate,
                icon: const Icon(Icons.navigation),
                label: const Text('Chỉ đường', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _onSendSos,
                icon: const Icon(Icons.warning, color: Colors.red),
                label: const Text('Cứu hộ SOS'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber[900],
                  side: BorderSide(color: Colors.amber[400]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _onWriteReview,
                icon: const Icon(Icons.star_outline, color: Colors.amber),
                label: const Text('Đánh giá'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    if (_isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_reviewError != null) {
      return Center(
        child: Column(
          children: [
            Text(_reviewError!, style: TextStyle(color: Colors.red[700])),
            TextButton(
              onPressed: _loadReviews,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Chưa có đánh giá nào cho tiệm này.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Hãy là người đầu tiên để lại đánh giá dịch vụ!',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reviews.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (_, index) => ReviewListItem(review: _reviews[index]),
    );
  }
}
