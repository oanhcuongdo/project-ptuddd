import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme.dart';
import '../../map/widgets/app_map_view.dart';
import '../navigation_helper.dart';

/// Màn hình chỉ đường trực tiếp (UC-06) theo tuyến đường bộ thực tế trên OpenStreetMap.
/// Tái sử dụng cho cả Rider (đến tiệm) và Owner / Volunteer (đến điểm sự cố).
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({
    super.key,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationTitle,
    this.destinationAddress,
    this.originTitle = 'Vị trí của bạn',
  });

  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final String destinationTitle;
  final String? destinationAddress;
  final String originTitle;

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  late final LatLng _origin;
  late final LatLng _destination;
  late double _distanceMeters;
  late int _estimatedMinutes;
  List<LatLng> _routePoints = const [];
  List<RouteStep> _steps = const [];
  bool _isRoadRoute = false;
  bool _isLoadingRoute = true;
  bool _routeFailed = false;
  bool _showSteps = false;

  @override
  void initState() {
    super.initState();
    _origin = LatLng(widget.originLat, widget.originLng);
    _destination = LatLng(widget.destinationLat, widget.destinationLng);

    _distanceMeters = NavigationHelper.calculateDistanceMeters(
      startLat: widget.originLat,
      startLng: widget.originLng,
      endLat: widget.destinationLat,
      endLng: widget.destinationLng,
    );

    _estimatedMinutes = NavigationHelper.estimateMotorbikeMinutes(
      _distanceMeters,
    );

    _loadRoadRoute();
  }

  Future<void> _loadRoadRoute() async {
    setState(() {
      _isLoadingRoute = true;
      _routeFailed = false;
    });

    final route = await NavigationHelper.fetchRoadRoute(
      originLat: widget.originLat,
      originLng: widget.originLng,
      destinationLat: widget.destinationLat,
      destinationLng: widget.destinationLng,
    );

    if (!mounted) return;
    if (route != null) {
      setState(() {
        _routePoints = route.points;
        _steps = route.steps;
        _distanceMeters = route.distanceMeters;
        _estimatedMinutes = route.durationMinutes;
        _isRoadRoute = true;
        _isLoadingRoute = false;
        _routeFailed = false;
      });
      _fitBounds();
    } else {
      setState(() {
        _routePoints = [_origin, _destination];
        _steps = const [];
        _isRoadRoute = false;
        _isLoadingRoute = false;
        _routeFailed = true;
      });
      _fitBounds();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitBounds() {
    if (!_mapReady) return;

    final allPoints = [..._routePoints, _origin, _destination];
    final bounds = LatLngBounds.fromPoints(allPoints);

    // Tránh lỗi khi điểm nguồn trùng điểm đích.
    if ((bounds.north - bounds.south).abs() < 1e-5 &&
        (bounds.east - bounds.west).abs() < 1e-5) {
      _mapController.move(_destination, 16);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(48, 84, 48, 320),
      ),
    );
  }

  List<Polyline> _buildPolylines() {
    if (_routePoints.length < 2) return const [];

    if (!_isRoadRoute) {
      return [
        Polyline(
          points: _routePoints,
          color: AppColors.primaryLight,
          strokeWidth: 4.5,
          pattern: StrokePattern.dashed(segments: const [12, 8]),
        ),
      ];
    }

    final lines = <Polyline>[
      // Tuyến đường bộ thực tế nổi bật có viền trắng/xanh đậm rõ ràng
      Polyline(
        points: _routePoints,
        color: AppColors.primary,
        borderColor: Colors.white,
        borderStrokeWidth: 2.5,
        strokeWidth: 6.5,
      ),
    ];

    // Nét nối mảnh từ vị trí GPS/ghim vào điểm bắt đầu/kết thúc trên mặt đường (nếu lệch > 20m)
    final startSnap = _routePoints.first;
    final endSnap = _routePoints.last;
    if (NavigationHelper.calculateDistanceMeters(
          startLat: _origin.latitude,
          startLng: _origin.longitude,
          endLat: startSnap.latitude,
          endLng: startSnap.longitude,
        ) >
        20) {
      lines.add(
        Polyline(
          points: [_origin, startSnap],
          color: AppColors.navyBrand.withValues(alpha: 0.65),
          strokeWidth: 3.5,
          pattern: const StrokePattern.dotted(spacingFactor: 1.8),
        ),
      );
    }
    if (NavigationHelper.calculateDistanceMeters(
          startLat: endSnap.latitude,
          startLng: endSnap.longitude,
          endLat: _destination.latitude,
          endLng: _destination.longitude,
        ) >
        20) {
      lines.add(
        Polyline(
          points: [endSnap, _destination],
          color: AppColors.sosRed.withValues(alpha: 0.7),
          strokeWidth: 3.5,
          pattern: const StrokePattern.dotted(spacingFactor: 1.8),
        ),
      );
    }

    return lines;
  }

  IconData _stepIcon(RouteStep step) {
    if (step.maneuverType == 'depart') return Icons.trip_origin_rounded;
    if (step.maneuverType == 'arrive') return Icons.flag_rounded;
    if (step.maneuverType == 'roundabout' || step.maneuverType == 'rotary') {
      return Icons.roundabout_right_rounded;
    }
    return switch (step.modifier) {
      'uturn' => Icons.u_turn_left_rounded,
      'sharp left' => Icons.turn_sharp_left_rounded,
      'left' => Icons.turn_left_rounded,
      'slight left' => Icons.turn_slight_left_rounded,
      'sharp right' => Icons.turn_sharp_right_rounded,
      'right' => Icons.turn_right_rounded,
      'slight right' => Icons.turn_slight_right_rounded,
      _ => Icons.straight_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      Marker(
        point: _origin,
        width: 28,
        height: 28,
        child: Tooltip(
          message: widget.originTitle,
          child: buildUserLocationMarker(),
        ),
      ),
      Marker(
        point: _destination,
        width: 170,
        height: 76,
        alignment: Alignment.bottomCenter,
        child: buildMapPin(
          color: AppColors.sosRed,
          icon: Icons.flag_rounded,
          selected: true,
          label: widget.destinationTitle,
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉ dẫn đường đi'),
        actions: [
          IconButton(
            tooltip: 'Tải lại tuyến đường',
            onPressed: _isLoadingRoute ? null : _loadRoadRoute,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Căn giữa lộ trình',
            onPressed: _fitBounds,
            icon: const Icon(Icons.center_focus_strong_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          AppMapView(
            mapController: _mapController,
            initialCenter: _origin,
            initialZoom: 14,
            showZoomButtons: true,
            markers: markers,
            polylines: _buildPolylines(),
            onMapReady: () {
              _mapReady = true;
              _fitBounds();
            },
          ),
          if (_isLoadingRoute)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDeep.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang tính tuyến đường bộ thực tế...',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 18,
            child: Card(
              elevation: 6,
              shadowColor: AppColors.navyDeep.withValues(alpha: 0.16),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoadingRoute)
                    const LinearProgressIndicator(minHeight: 3),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.navigation_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.destinationTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.destinationAddress != null &&
                                      widget.destinationAddress!
                                          .trim()
                                          .isNotEmpty)
                                    Text(
                                      widget.destinationAddress!,
                                      style: const TextStyle(
                                        color: AppColors.inkSecondary,
                                        fontSize: 12.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (_isRoadRoute)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.success.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.alt_route_rounded,
                                      size: 13,
                                      color: Color(0xFF047857),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Đường bộ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF047857),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (_routeFailed) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: Color(0xFFB45309),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Không tải được tuyến đường chi tiết — hiển thị đường thẳng ước tính.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed: _loadRoadRoute,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetric(
                              icon: Icons.straighten_rounded,
                              label: _isRoadRoute
                                  ? 'Quãng đường'
                                  : 'Đường thẳng',
                              value: NavigationHelper.formatDistance(
                                _distanceMeters,
                              ),
                              color: AppColors.primary,
                            ),
                            Container(
                              height: 30,
                              width: 1,
                              color: AppColors.border,
                            ),
                            _buildMetric(
                              icon: Icons.two_wheeler_rounded,
                              label: _isRoadRoute
                                  ? 'Thời gian dự kiến'
                                  : 'Xe máy ước tính',
                              value: NavigationHelper.formatDuration(
                                _estimatedMinutes,
                              ),
                              color: AppColors.motoOrange,
                            ),
                          ],
                        ),
                        if (_steps.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () =>
                                setState(() => _showSteps = !_showSteps),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.turn_right_rounded,
                                    size: 17,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Hướng dẫn theo lộ trình (${_steps.length} chặng)',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.inkPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _showSteps
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                    color: AppColors.inkSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showSteps)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 150),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.only(top: 8),
                                itemCount: _steps.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, index) {
                                  final step = _steps[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _stepIcon(step),
                                          size: 18,
                                          color: step.maneuverType == 'arrive'
                                              ? AppColors.sosRed
                                              : AppColors.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            step.instruction,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (step.distanceMeters > 0)
                                          Text(
                                            NavigationHelper.formatDistance(
                                              step.distanceMeters,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.inkSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: () =>
                                NavigationHelper.openExternalGoogleMaps(
                              destinationLat: widget.destinationLat,
                              destinationLng: widget.destinationLng,
                              context: context,
                            ),
                            icon: const Icon(Icons.directions_rounded),
                            label: const Text('Mở ứng dụng Google Maps ngoài'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.inkSecondary),
        ),
      ],
    );
  }
}
