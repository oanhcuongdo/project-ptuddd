import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/hci_components.dart';
import '../../../models/review.dart';
import '../../../models/shop.dart';
import '../../../repositories/shop_repository.dart';
import '../../call/call_helper.dart';
import '../../navigation/navigation_helper.dart';
import '../../navigation/screens/navigation_screen.dart';
import '../../review/data/supabase_review_repository.dart';
import '../../review/widgets/review_form.dart';
import '../../review/widgets/review_list_item.dart';
import '../../sos/screens/sos_request_screen.dart';

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
      if (!mounted) return;
      if (updated == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Địa điểm không còn tồn tại trên hệ thống'),
          ),
        );
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        // Giữ lại khoảng cách distanceM và tên chủ tiệm đã có từ RPC tìm quanh đây.
        _shop = Shop(
          id: updated.id,
          ownerId: updated.ownerId,
          name: updated.name,
          category: updated.category,
          phone: updated.phone,
          address: updated.address,
          latitude: updated.latitude,
          longitude: updated.longitude,
          openTime: updated.openTime,
          closeTime: updated.closeTime,
          isOpen: updated.isOpen,
          imageUrl: updated.imageUrl,
          rating: updated.rating,
          reviewCount: updated.reviewCount,
          status: updated.status,
          rejectionReason: updated.rejectionReason,
          createdAt: updated.createdAt,
          distanceM: _shop.distanceM,
          ownerName: updated.ownerName ?? _shop.ownerName,
        );
      });
    } catch (_) {}
  }

  String _formatClock(String time) =>
      time.length >= 5 ? time.substring(0, 5) : time;

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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SosRequestScreen()),
    );
  }

  Future<void> _onWriteReview() async {
    final sent = await showReviewSheet(
      context,
      shopId: _shop.id,
      shopName: _shop.name,
    );
    if (sent && mounted) {
      await _loadReviews();
      await _refreshShopData();
    }
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
                  // Thông tin chi tiết trong thẻ sáng dễ đọc
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          if (_shop.ownerName != null &&
                              _shop.ownerName!.trim().isNotEmpty) ...[
                            _buildInfoRow(
                              icon: Icons.person_outline,
                              text: 'Chủ tiệm: ${_shop.ownerName!.trim()}',
                              color: Colors.teal,
                            ),
                            const SizedBox(height: 10),
                          ],
                          _buildInfoRow(
                            icon: Icons.location_on,
                            text: _shop.address,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            icon: Icons.access_time,
                            text:
                                'Giờ mở cửa: ${_formatClock(_shop.openTime)} - ${_formatClock(_shop.closeTime)}',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            icon: Icons.phone,
                            text: 'Hotline: ${_shop.phone}',
                            color: Colors.green,
                          ),
                          if (_shop.distanceM != null) ...[
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              icon: Icons.straighten,
                              text:
                                  'Khoảng cách: ${NavigationHelper.formatDistance(_shop.distanceM!)}',
                              color: Colors.indigo,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

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
      height: 196,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRepair
              ? [const Color(0xFFEA580C), AppColors.motoAmber]
              : [AppColors.navyBrand, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(
              isRepair
                  ? Icons.build_circle_rounded
                  : Icons.local_gas_station_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: AppColors.inkPrimary,
              fontWeight: FontWeight.w500,
            ),
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
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _onCall,
                icon: const Icon(Icons.phone_rounded),
                label: const Text(
                  'Gọi ngay',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _onNavigate,
                icon: const Icon(Icons.navigation_rounded),
                label: const Text(
                  'Chỉ đường',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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
                  backgroundColor: AppColors.dangerBg,
                  foregroundColor: AppColors.sosRedDark,
                  side: BorderSide(
                    color: AppColors.sosRed.withValues(alpha: 0.35),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _onSendSos,
                icon: const Icon(Icons.sos_rounded, color: AppColors.sosRed),
                label: const Text('Cứu hộ SOS'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.warningBg,
                  foregroundColor: const Color(0xFF92400E),
                  side: BorderSide(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _onWriteReview,
                icon: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFD97706),
                ),
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
      return Card(
        margin: EdgeInsets.zero,
        child: EmptyStateCard(
          icon: Icons.rate_review_outlined,
          title: 'Chưa có đánh giá nào',
          message: 'Hãy là người đầu tiên để lại đánh giá dịch vụ cho tiệm này!',
          accentColor: AppColors.primary,
          action: OutlinedButton.icon(
            onPressed: _onWriteReview,
            icon: const Icon(Icons.star_outline_rounded),
            label: const Text('Viết đánh giá đầu tiên'),
          ),
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
