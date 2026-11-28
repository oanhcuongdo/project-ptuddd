import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../navigation_helper.dart';

/// Màn hình chỉ đường trực tiếp (UC-06).
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
  GoogleMapController? _mapController;

  late final LatLng _origin;
  late final LatLng _destination;
  late final double _distanceMeters;
  late final int _estimatedMinutes;

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

    _estimatedMinutes =
        NavigationHelper.estimateMotorbikeMinutes(_distanceMeters);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (_mapController == null) return;

    final southWestLat = math.min(_origin.latitude, _destination.latitude);
    final southWestLng = math.min(_origin.longitude, _destination.longitude);
    final northEastLat = math.max(_origin.latitude, _destination.latitude);
    final northEastLng = math.max(_origin.longitude, _destination.longitude);

    final bounds = LatLngBounds(
      southwest: LatLng(southWestLat, southWestLng),
      northeast: LatLng(northEastLat, northEastLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('origin'),
        position: _origin,
        infoWindow: InfoWindow(title: widget.originTitle),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: _destination,
        infoWindow: InfoWindow(title: widget.destinationTitle),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_origin, _destination],
        color: const Color(0xFF1E88E5),
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉ dẫn đường đi'),
        actions: [
          IconButton(
            tooltip: 'Căn giữa lộ trình',
            onPressed: _fitBounds,
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _origin,
              zoom: 14,
            ),
            onMapCreated: _onMapCreated,
            markers: markers,
            polylines: polylines,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFE3F2FD),
                          child: Icon(Icons.navigation, color: Color(0xFF1E88E5)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.destinationTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.destinationAddress != null)
                                Text(
                                  widget.destinationAddress!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric(
                          icon: Icons.straighten,
                          label: 'Khoảng cách',
                          value: NavigationHelper.formatDistance(_distanceMeters),
                          color: Colors.blueAccent,
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        _buildMetric(
                          icon: Icons.two_wheeler,
                          label: 'Xe máy ước tính',
                          value: NavigationHelper.formatDuration(_estimatedMinutes),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            NavigationHelper.openExternalGoogleMaps(
                          destinationLat: widget.destinationLat,
                          destinationLng: widget.destinationLng,
                          context: context,
                        ),
                        icon: const Icon(Icons.directions),
                        label: const Text(
                          'Mở ứng dụng Google Maps ngoài',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
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
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
