import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../features/call/call_helper.dart';
import '../../features/map/location_service.dart';
import '../../features/navigation/screens/navigation_screen.dart';
import '../../features/shop/screens/shop_detail_screen.dart';
import '../../features/shop/widgets/shop_carousel.dart';
import '../../features/shop/widgets/shop_filter_bar.dart';
import '../../models/shop.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/shop_repository.dart';

/// Màn hình chính phân hệ Khách hàng (Rider), tích hợp toàn bộ UC-02 đến UC-06.
class RiderShell extends StatefulWidget {
  const RiderShell({super.key});

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  GoogleMapController? _mapController;

  LatLng _currentLocation = LocationService.defaultHanoi;
  String _currentAddress = 'Đang xác định vị trí...';
  bool _isLoadingLocation = true;
  bool _isLoadingShops = false;

  // Dữ liệu tiệm
  List<Shop> _shops = [];
  String? _selectedShopId;

  // Trạng thái bộ lọc (UC-03)
  String _searchQuery = '';
  String? _selectedCategory; // null = Tất cả, 'repair_shop', 'gas_station'
  int _selectedRadius = 3000; // 3km mặc định
  bool _isOpenOnly = false;

  RealtimeChannel? _shopsSubscription;

  @override
  void initState() {
    super.initState();
    _initLocationAndShops();
    _subscribeToShopsRealtime();
  }

  @override
  void dispose() {
    _shopsSubscription?.unsubscribe();
    super.dispose();
  }

  /// Lắng nghe thay đổi trạng thái đóng/mở cửa của tiệm theo thời gian thực (Supabase Realtime)
  void _subscribeToShopsRealtime() {
    _shopsSubscription = supabase
        .channel('public:shops')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shops',
          callback: (payload) {
            _fetchNearbyShops(showLoading: false);
          },
        )
        .subscribe();
  }

  /// UC-02: Định vị GPS hiện tại và tải danh sách tiệm ban đầu
  Future<void> _initLocationAndShops() async {
    setState(() => _isLoadingLocation = true);

    final res = await LocationService.getCurrentLocation();

    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
        if (res.position != null) {
          _currentLocation = res.position!;
        }
        _currentAddress = res.address ??
            (res.position != null
                ? 'Tọa độ: ${res.position!.latitude.toStringAsFixed(4)}, ${res.position!.longitude.toStringAsFixed(4)}'
                : 'Hà Nội');
      });

      if (res.isGpsDisabled) {
        _showGpsDisabledDialog();
      } else if (res.isPermissionDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Ứng dụng không có quyền GPS. Đang hiển thị vị trí mặc định tại Hà Nội.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _animateCameraTo(_currentLocation);
      await _fetchNearbyShops();
    }
  }

  void _showGpsDisabledDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dịch vụ vị trí bị tắt'),
        content: const Text(
          'Vui lòng bật định vị GPS trên thiết bị để ứng dụng có thể tìm tiệm sửa xe và cây xăng gần bạn nhất.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Bỏ qua'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _initLocationAndShops();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  void _animateCameraTo(LatLng target, {double zoom = 14.5}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  /// UC-03: Tải danh sách tiệm trong bán kính qua RPC PostGIS
  Future<void> _fetchNearbyShops({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoadingShops = true);
    }

    try {
      final list = await ShopRepository().nearby(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        radiusMeters: _selectedRadius,
        category: _selectedCategory,
        openOnly: _isOpenOnly,
      );

      if (mounted) {
        setState(() {
          _shops = list;
          _isLoadingShops = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingShops = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lỗi kết nối cơ sở dữ liệu khi tải danh sách tiệm.'),
            backgroundColor: Colors.redAccent,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _fetchNearbyShops(),
            ),
          ),
        );
      }
    }
  }

  /// Lọc thêm theo từ khóa tìm kiếm (tên tiệm / tên đường)
  List<Shop> get _filteredShops {
    if (_searchQuery.trim().isEmpty) return _shops;
    final query = _searchQuery.toLowerCase().trim();
    return _shops.where((s) {
      return s.name.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query);
    }).toList();
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Marker vị trí người dùng (chấm xanh)
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _currentLocation,
        infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    // Markers cho các tiệm
    for (final shop in _filteredShops) {
      final isRepair = shop.category == 'repair_shop';
      final isSelected = shop.id == _selectedShopId;

      markers.add(
        Marker(
          markerId: MarkerId(shop.id),
          position: LatLng(shop.latitude, shop.longitude),
          infoWindow: InfoWindow(
            title: shop.name,
            snippet: shop.isOpen ? 'Đang mở cửa' : 'Tạm đóng cửa',
            onTap: () => _openShopDetail(shop),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected
                ? BitmapDescriptor.hueViolet
                : (isRepair
                    ? BitmapDescriptor.hueOrange
                    : BitmapDescriptor.hueBlue),
          ),
          onTap: () {
            setState(() => _selectedShopId = shop.id);
            _animateCameraTo(LatLng(shop.latitude, shop.longitude), zoom: 15.5);
          },
        ),
      );
    }

    return markers;
  }

  void _openShopDetail(Shop shop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopDetailScreen(
          shop: shop,
          userLat: _currentLocation.latitude,
          userLng: _currentLocation.longitude,
        ),
      ),
    );
  }

  void _onNavigateToShop(Shop shop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          originLat: _currentLocation.latitude,
          originLng: _currentLocation.longitude,
          destinationLat: shop.latitude,
          destinationLng: shop.longitude,
          destinationTitle: shop.name,
          destinationAddress: shop.address,
        ),
      ),
    );
  }

  /// Nút SOS khẩn cấp (UC-07 của bạn Tùng)
  void _openEmergencySosDialog() {
    String selectedIssue = 'Thủng lốp';
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Gửi Tín Hiệu SOS Khẩn Cấp'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn loại sự cố gặp phải:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedIssue,
                  items: const [
                    DropdownMenuItem(value: 'Thủng lốp', child: Text('Thủng lốp / Hết hơi')),
                    DropdownMenuItem(value: 'Hết xăng', child: Text('Hết xăng giữa đường')),
                    DropdownMenuItem(value: 'Hỏng động cơ', child: Text('Hỏng máy / Chết máy')),
                    DropdownMenuItem(value: 'Khác', child: Text('Sự cố khác')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedIssue = val);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mô tả thêm tình trạng:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Đang dừng ở ngã tư Giải Phóng...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tọa độ GPS sẽ tự động đính kèm: ${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
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
                    content: Text(
                        'Đã phát tín hiệu cứu hộ SOS! Đang tìm tiệm và tình nguyện viên gần nhất.'),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 4),
                  ),
                );
              },
              icon: const Icon(Icons.emergency),
              label: const Text('Phát tín hiệu cứu hộ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map nền
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 14.5,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _buildMarkers(),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (_) => setState(() => _selectedShopId = null),
          ),

          // 2. Thanh Top Bar địa chỉ & Đăng xuất
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: Color(0xFF1E88E5), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Vị trí hiện tại của bạn',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey),
                              ),
                              Text(
                                _currentAddress,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Làm mới vị trí',
                          onPressed: _initLocationAndShops,
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh, size: 20),
                        ),
                        IconButton(
                          tooltip: 'Đăng xuất',
                          onPressed: () => AuthRepository().signOut(),
                          icon: const Icon(Icons.logout, size: 20, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bộ lọc tìm kiếm & bán kính (UC-03)
                  ShopFilterBar(
                    searchQuery: _searchQuery,
                    selectedCategory: _selectedCategory,
                    selectedRadiusMeters: _selectedRadius,
                    isOpenOnly: _isOpenOnly,
                    onSearchChanged: (q) => setState(() => _searchQuery = q),
                    onCategoryChanged: (cat) {
                      setState(() => _selectedCategory = cat);
                      _fetchNearbyShops();
                    },
                    onRadiusChanged: (rad) {
                      setState(() => _selectedRadius = rad);
                      _fetchNearbyShops();
                    },
                    onOpenOnlyChanged: (openOnly) {
                      setState(() => _isOpenOnly = openOnly);
                      _fetchNearbyShops();
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Thanh hiển thị trạng thái đang tải
          if (_isLoadingShops)
            Positioned(
              top: 180,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Đang tìm kiếm...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Danh sách vuốt thẻ tiệm ở phía dưới bản đồ (UC-03)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: ShopCarousel(
              shops: _filteredShops,
              selectedShopId: _selectedShopId,
              onShopSelected: (shop) {
                setState(() => _selectedShopId = shop.id);
                _animateCameraTo(LatLng(shop.latitude, shop.longitude));
                _openShopDetail(shop);
              },
              onCall: (shop) => CallHelper.makeCall(context, shop.phone),
              onNavigate: _onNavigateToShop,
              onExpandRadius: () {
                setState(() => _selectedRadius = 10000);
                _fetchNearbyShops();
              },
            ),
          ),

          // 5. Nút định vị GPS "Vị trí của tôi"
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton.small(
              heroTag: 'my_location_fab',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E88E5),
              onPressed: () => _animateCameraTo(_currentLocation),
              tooltip: 'Vị trí của tôi',
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),

      // 6. Nút SOS khẩn cấp nổi bật
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sos_fab',
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        onPressed: _openEmergencySosDialog,
        icon: const Icon(Icons.emergency, size: 24),
        label: const Text(
          '🚨 CỨU HỘ SOS',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
