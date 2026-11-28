import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/hci_components.dart';
import '../../features/call/call_helper.dart';
import '../../features/map/location_service.dart';
import '../../features/map/widgets/app_map_view.dart';
import '../../features/navigation/screens/navigation_screen.dart';
import '../../features/shop/screens/shop_detail_screen.dart';
import '../../features/shop/shop_filter.dart';
import '../../features/shop/widgets/shop_carousel.dart';
import '../../features/shop/widgets/shop_filter_bar.dart';
import '../../features/sos/screens/sos_request_screen.dart';
import '../../models/shop.dart';
import '../../repositories/shop_repository.dart';

/// Màn hình chính phân hệ Khách hàng (Rider), tích hợp UC-02 → UC-08.
class RiderShell extends StatefulWidget {
  const RiderShell({super.key});

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  LatLng _currentLocation = LocationService.defaultHanoi;
  String _currentAddress = 'Đang xác định vị trí...';
  bool _isLoadingLocation = true;
  bool _isLoadingShops = false;
  bool _locationDenied = false;

  // Dữ liệu tiệm
  List<Shop> _shops = [];
  String? _selectedShopId;

  // Trạng thái bộ lọc & sắp xếp (UC-03)
  String _searchQuery = '';
  String? _selectedCategory; // null = Tất cả, 'repair_shop', 'gas_station'
  int _selectedRadius = 3000; // 3km mặc định
  bool _isOpenOnly = false;
  ShopSort _selectedSort = ShopSort.nearest;

  RealtimeChannel? _shopsSubscription;

  @override
  void initState() {
    super.initState();
    _initLocationAndShops();
    _subscribeToShopsRealtime();
  }

  @override
  void dispose() {
    final channel = _shopsSubscription;
    if (channel != null) {
      unawaited(supabase.removeChannel(channel));
    }
    _mapController.dispose();
    super.dispose();
  }

  /// Lắng nghe thay đổi trạng thái đóng/mở cửa của tiệm theo thời gian thực (Supabase Realtime).
  void _subscribeToShopsRealtime() {
    _shopsSubscription = supabase
        .channel('public:shops-${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shops',
          callback: (_) {
            if (!_locationDenied) {
              _fetchNearbyShops(showLoading: false);
            }
          },
        )
        .subscribe();
  }

  /// UC-02: Định vị GPS hiện tại và tải danh sách tiệm ban đầu.
  Future<void> _initLocationAndShops() async {
    setState(() => _isLoadingLocation = true);

    final res = await LocationService.getCurrentLocation();

    if (!mounted) return;
    setState(() {
      _isLoadingLocation = false;
      _locationDenied = res.isPermissionDenied;
      if (res.position != null) {
        _currentLocation = res.position!;
      }
      if (res.isPermissionDenied) {
        _currentLocation = LocationService.defaultHanoi;
        _currentAddress = 'Chưa cấp quyền vị trí (mặc định Hà Nội)';
        _shops = [];
        _selectedShopId = null;
      } else {
        _currentAddress = res.address ??
            (res.position != null
                ? 'Tọa độ: ${res.position!.latitude.toStringAsFixed(4)}, ${res.position!.longitude.toStringAsFixed(4)}'
                : 'Hà Nội');
      }
    });

    if (res.isPermissionDenied) {
      // UC-02 ngoại lệ: từ chối quyền vị trí -> chỉ hiển thị bản đồ mặc định tại Hà Nội,
      // không thực hiện tìm kiếm quanh đây cho đến khi người dùng cấp quyền.
      _animateCameraTo(LocationService.defaultHanoi, zoom: 12.5);
      return;
    }

    if (res.isGpsDisabled) {
      _showGpsDisabledDialog();
    } else if (res.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage!),
          backgroundColor: Colors.orange,
        ),
      );
    }

    _animateCameraTo(_currentLocation);
    await _fetchNearbyShops();
  }

  void _showGpsDisabledDialog() {
    showDialog<void>(
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
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(Geolocator.openLocationSettings());
            },
            child: const Text('Mở cài đặt'),
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
    if (!_mapReady) return;
    _mapController.move(target, zoom);
  }

  /// UC-03: Tải danh sách tiệm trong bán kính qua RPC PostGIS.
  Future<void> _fetchNearbyShops({bool showLoading = true}) async {
    if (_locationDenied) return;
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

  List<Shop> get _filteredShops =>
      sortShops(filterShops(_shops, _searchQuery), _selectedSort);

  List<Marker> _buildMarkers() {
    final markers = <Marker>[
      // Marker vị trí người dùng (chấm xanh)
      Marker(
        point: _currentLocation,
        width: 28,
        height: 28,
        child: Tooltip(
          message: _locationDenied ? 'Hà Nội (mặc định)' : 'Vị trí của bạn',
          child: buildUserLocationMarker(),
        ),
      ),
    ];

    Shop? selectedShop;
    for (final shop in _filteredShops) {
      if (shop.id == _selectedShopId) {
        selectedShop = shop;
        continue;
      }
      markers.add(_buildShopMarker(shop, selected: false));
    }
    // Vẽ tiệm đang chọn sau cùng để nổi lên trên các ghim xung quanh.
    if (selectedShop != null) {
      markers.add(_buildShopMarker(selectedShop, selected: true));
    }

    return markers;
  }

  Marker _buildShopMarker(Shop shop, {required bool selected}) {
    final isRepair = shop.category == 'repair_shop';
    final color = selected
        ? const Color(0xFF6A1B9A)
        : (isRepair ? const Color(0xFFEF6C00) : const Color(0xFF1565C0));
    return Marker(
      point: LatLng(shop.latitude, shop.longitude),
      width: selected ? 170 : 40,
      height: selected ? 76 : 40,
      alignment: selected ? Alignment.bottomCenter : Alignment.center,
      child: buildMapPin(
        color: color,
        icon: isRepair ? Icons.build : Icons.local_gas_station,
        selected: selected,
        label: selected ? shop.name : null,
        onTap: () {
          if (selected) {
            _openShopDetail(shop);
          } else {
            setState(() => _selectedShopId = shop.id);
            _animateCameraTo(LatLng(shop.latitude, shop.longitude), zoom: 15.5);
          }
        },
      ),
    );
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

  /// UC-07: mở màn hình gửi/theo dõi tín hiệu SOS thực tế.
  void _openSosScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SosRequestScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Bản đồ OpenStreetMap dùng chung
          AppMapView(
            mapController: _mapController,
            initialCenter: _currentLocation,
            initialZoom: 14.5,
            markers: _buildMarkers(),
            onTap: (_) => setState(() => _selectedShopId = null),
            onMapReady: () {
              _mapReady = true;
              _animateCameraTo(
                _currentLocation,
                zoom: _locationDenied ? 12.5 : 14.5,
              );
            },
          ),

          // 2. Thanh Top Bar địa chỉ & Đăng xuất
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _locationDenied
                                ? AppColors.warningBg
                                : AppColors.infoBg,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            _locationDenied
                                ? Icons.location_off_rounded
                                : Icons.my_location_rounded,
                            color: _locationDenied
                                ? AppColors.warning
                                : AppColors.primary,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  LiveStatusDot(
                                    color: _locationDenied
                                        ? AppColors.warning
                                        : AppColors.success,
                                    size: 6,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Vị trí hiện tại của bạn',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _currentAddress,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.inkPrimary,
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                        ),
                        IconButton(
                          tooltip: 'Đăng xuất',
                          onPressed: () => confirmAndSignOut(context),
                          icon: const Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_locationDenied)
                    _buildLocationDeniedBanner()
                  else
                    // Bộ lọc tìm kiếm, bán kính & sắp xếp (UC-03)
                    ShopFilterBar(
                      searchQuery: _searchQuery,
                      selectedCategory: _selectedCategory,
                      selectedRadiusMeters: _selectedRadius,
                      isOpenOnly: _isOpenOnly,
                      selectedSort: _selectedSort,
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
                      onSortChanged: (sort) => setState(() => _selectedSort = sort),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
          if (!_locationDenied)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
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

          // 5. Nút SOS khẩn cấp nổi bật có quầng sáng nhận diện nhanh (Fitts's Law)
          Positioned(
            left: 16,
            bottom: _locationDenied ? 24 : 182,
            child: _PulsingSosFab(onPressed: _openSosScreen),
          ),

          // 6. Nút định vị GPS "Vị trí của tôi"
          Positioned(
            right: 16,
            bottom: _locationDenied ? 28 : 186,
            child: FloatingActionButton.small(
              heroTag: 'my_location_fab',
              elevation: 3,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              onPressed: _locationDenied
                  ? _initLocationAndShops
                  : () => _animateCameraTo(_currentLocation),
              tooltip: 'Vị trí của tôi',
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDeniedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_off, color: Color(0xFFE65100), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chưa có quyền truy cập vị trí GPS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ứng dụng đang hiển thị bản đồ mặc định tại Hà Nội. Vui lòng cấp quyền vị trí để tìm kiếm tiệm sửa xe và cây xăng quanh bạn.',
            style: TextStyle(fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  backgroundColor: const Color(0xFFE65100),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () => unawaited(Geolocator.openAppSettings()),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('Cấp quyền vị trí'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: _initLocationAndShops,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nút Cứu hộ SOS có hiệu ứng nhịp sáng nhẹ giúp người gặp sự cố nhận diện tức thì.
class _PulsingSosFab extends StatefulWidget {
  const _PulsingSosFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_PulsingSosFab> createState() => _PulsingSosFabState();
}

class _PulsingSosFabState extends State<_PulsingSosFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = disableAnimations ? 0.25 : 0.18 + 0.22 * _pulse.value;
        final spread = disableAnimations ? 2.0 : 1.0 + 4.5 * _pulse.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.sosRed.withValues(alpha: glow),
                blurRadius: 16,
                spreadRadius: spread,
              ),
            ],
          ),
          child: child,
        );
      },
      child: FloatingActionButton.extended(
        heroTag: 'sos_fab',
        elevation: 4,
        backgroundColor: AppColors.sosRed,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: widget.onPressed,
        icon: const Icon(Icons.sos_rounded),
        label: const Text(
          'CỨU HỘ SOS',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4),
        ),
      ),
    );
  }
}
