import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget bản đồ OpenStreetMap dùng chung cho toàn bộ ứng dụng
/// (Rider UC-02/03, Chỉ đường UC-06, Ghim vị trí tiệm UC-10, Khu vực TNV UC-13).
/// Miễn phí, không cần Google Maps API Key hay thẻ Billing.
class AppMapView extends StatelessWidget {
  const AppMapView({
    super.key,
    required this.initialCenter,
    this.initialZoom = 14.5,
    this.mapController,
    this.markers = const [],
    this.polylines = const [],
    this.onTap,
    this.onMapReady,
    this.showZoomButtons = false,
  });

  // Esri World Street Map: bản đồ đường phố tiếng Việt sắc nét, miễn phí qua Akamai CDN, không cần API key.
  static const _tileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  static const _userAgentPackage = 'com.example.ketnoitinhnguyenvienxemay';

  final LatLng initialCenter;
  final double initialZoom;
  final MapController? mapController;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final ValueChanged<LatLng>? onTap;
  final VoidCallback? onMapReady;
  final bool showZoomButtons;

  void _stepZoom(double delta) {
    final controller = mapController;
    if (controller == null) return;
    final cam = controller.camera;
    final nextZoom = (cam.zoom + delta).clamp(4.0, 19.0);
    controller.move(cam.center, nextZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            backgroundColor: const Color(0xFFE8EDF2),
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            minZoom: 4,
            maxZoom: 19,
            onTap: onTap == null ? null : (_, point) => onTap!(point),
            onMapReady: onMapReady,
          ),
          children: [
            TileLayer(
              urlTemplate: _tileUrl,
              userAgentPackageName: _userAgentPackage,
              maxNativeZoom: 18,
              errorTileCallback: (tile, error, stackTrace) {
                debugPrint('Map tile error (${tile.coordinates}): $error');
              },
            ),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        ),
        // Ghi nguồn dữ liệu bản đồ
        Positioned(
          left: 8,
          bottom: 4,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '© Esri · OpenStreetMap',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          ),
        ),
        if (showZoomButtons && mapController != null)
          Positioned(
            right: 12,
            bottom: 16,
            child: Material(
              elevation: 3,
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Phóng to',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _stepZoom(1),
                    icon: const Icon(Icons.add, size: 20),
                  ),
                  const Divider(height: 1, indent: 6, endIndent: 6),
                  IconButton(
                    tooltip: 'Thu nhỏ',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _stepZoom(-1),
                    icon: const Icon(Icons.remove, size: 20),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Chấm xanh định vị vị trí người dùng dùng chung trên bản đồ.
Widget buildUserLocationMarker() {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF1565C0).withValues(alpha: 0.22),
    ),
    padding: const EdgeInsets.all(5),
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1565C0),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    ),
  );
}

/// Ghim địa điểm bo tròn nổi bật (tiệm sửa xe, cây xăng, điểm đích, vị trí ghim).
Widget buildMapPin({
  required Color color,
  required IconData icon,
  bool selected = false,
  String? label,
  VoidCallback? onTap,
}) {
  final size = selected ? 42.0 : 34.0;
  final pin = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: selected ? 3 : 2.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: selected ? 8 : 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: selected ? 22 : 18),
  );

  final content = label == null
      ? pin
      : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 160),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 3),
            pin,
          ],
        );

  return onTap == null
      ? content
      : GestureDetector(onTap: onTap, child: content);
}
