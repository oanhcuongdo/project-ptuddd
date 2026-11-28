import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/place_plan.dart';
import '../models/place_suggestion.dart';
import '../providers/itinerary_providers.dart';
import '../repository/itinerary_repository.dart';
import 'add_activity_screen.dart';

class RouteMapScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String? destinationName;
  final double? initialLat;
  final double? initialLng;
  const RouteMapScreen({
    super.key,
    required this.tripId,
    this.destinationName,
    this.initialLat,
    this.initialLng,
  });
  @override
  ConsumerState<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends ConsumerState<RouteMapScreen> {
  GoogleMapController? mapController;
  String query = '';
  late double _centerLat = widget.initialLat ?? 10.7769;
  late double _centerLon = widget.initialLng ?? 106.7009;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initMapAndSuggestions);
  }

  Future<void> _initMapAndSuggestions() async {
    final plans = ref.read(itineraryProvider(widget.tripId)).plans;
    if (plans.isNotEmpty) {
      _centerLat = plans.first.latitude;
      _centerLon = plans.first.longitude;
    } else if ((widget.initialLat == null || widget.initialLng == null) &&
        (widget.destinationName?.trim().isNotEmpty ?? false)) {
      final resolved = await ref
          .read(placeDiscoveryRepositoryProvider)
          .resolveDestinationCoordinates(widget.destinationName!);
      if (resolved != null && mounted) {
        setState(() {
          _centerLat = resolved.lat;
          _centerLon = resolved.lon;
        });
      }
    }

    await mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(_centerLat, _centerLon)),
    );
    if (!mounted) return;
    await ref.read(itineraryProvider(widget.tripId).notifier).searchSuggestions(
          latitude: _centerLat,
          longitude: _centerLon,
          destinationName: widget.destinationName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(selectedDayProvider(widget.tripId));
    final state = ref.watch(itineraryProvider(widget.tripId));
    final plans = state.forDay(day);
    final filter = ref.watch(suggestionFilterProvider);
    final suggestions = state.suggestions
        .where((s) => filter == null || s.category == filter)
        .toList();
    final markers = <Marker>{
      ...plans.map(
        (p) => Marker(
          markerId: MarkerId(p.id),
          position: LatLng(p.latitude, p.longitude),
          infoWindow: InfoWindow(title: p.placeName),
        ),
      ),
      ...suggestions.map(
        (s) => Marker(
          markerId: MarkerId(s.id),
          position: LatLng(s.latitude, s.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(_hue(s.category)),
          onTap: () => _addSuggestion(s),
        ),
      ),
    };
    final points = plans.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final km = _distance(plans);
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ & check-in')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm địa điểm...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => query = v),
              onSubmitted: (_) => ref
                  .read(itineraryProvider(widget.tripId).notifier)
                  .searchSuggestions(
                    query: query,
                    category: filter,
                    latitude: _centerLat,
                    longitude: _centerLon,
                    destinationName: widget.destinationName,
                  ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in <String, PlaceCategory?>{
                  'Tất cả': null,
                  'Tham quan': PlaceCategory.attraction,
                  'Ăn uống': PlaceCategory.food,
                  'Khách sạn': PlaceCategory.hotel,
                }.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(entry.key),
                      selected: entry.value == filter,
                      onSelected: (_) {
                        ref.read(suggestionFilterProvider.notifier).state =
                            entry.value;
                        ref
                            .read(itineraryProvider(widget.tripId).notifier)
                            .searchSuggestions(
                              query: query,
                              category: entry.value,
                              latitude: _centerLat,
                              longitude: _centerLon,
                              destinationName: widget.destinationName,
                            );
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 280,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_centerLat, _centerLon),
                zoom: 12,
              ),
              markers: markers,
              polylines: {
                if (points.length > 1)
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: points,
                    color: Colors.blue,
                    width: 5,
                  ),
              },
              onMapCreated: (c) {
                mapController = c;
                c.moveCamera(
                  CameraUpdate.newLatLng(LatLng(_centerLat, _centerLon)),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Lộ trình ngày $day: ${km.toStringAsFixed(1)} km • khoảng ${(km * 3).ceil()} phút di chuyển',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final suggestion in suggestions)
                  ListTile(
                    leading: const Icon(Icons.place),
                    title: Text(suggestion.name),
                    subtitle: Text(suggestion.address),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () => _addSuggestion(suggestion),
                    ),
                  ),
                for (final plan in plans)
                  ListTile(
                    title: Text(plan.placeName),
                    subtitle: Text(
                      plan.isCheckedIn ? 'Đã check-in' : 'Chưa check-in',
                    ),
                    trailing: plan.isCheckedIn
                        ? TextButton.icon(
                            onPressed: plan.checkInPhotoUrl != null &&
                                    plan.checkInPhotoUrl!.isNotEmpty
                                ? () => _showCheckInPhoto(plan)
                                : null,
                            icon: const Icon(Icons.verified, size: 18),
                            label: Text(
                              plan.checkInPhotoUrl != null &&
                                      plan.checkInPhotoUrl!.isNotEmpty
                                  ? 'Xem ảnh'
                                  : 'Đã check-in',
                            ),
                          )
                        : FilledButton(
                            onPressed: () => _checkIn(plan),
                            child: const Text('Check-in'),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _hue(PlaceCategory c) => switch (c) {
    PlaceCategory.attraction => BitmapDescriptor.hueRed,
    PlaceCategory.food => BitmapDescriptor.hueOrange,
    PlaceCategory.hotel => BitmapDescriptor.hueGreen,
  };
  Future<void> _addSuggestion(PlaceSuggestion suggestion) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddActivityScreen(tripId: widget.tripId, suggestion: suggestion),
      ),
    );
  }

  double _distance(List<PlacePlan> plans) {
    var total = 0.0;
    for (var i = 1; i < plans.length; i++) {
      total +=
          Geolocator.distanceBetween(
            plans[i - 1].latitude,
            plans[i - 1].longitude,
            plans[i].latitude,
            plans[i].longitude,
          ) /
          1000;
    }
    return total;
  }

  Future<bool> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      await openAppSettings();
      return false;
    }
    return status.isGranted || status.isLimited;
  }

  Future<bool> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      await openAppSettings();
      return false;
    }
    return status.isGranted || status.isLimited;
  }

  Future<void> _checkIn(PlacePlan plan) async {
    try {
      if (!await _requestLocationPermission()) {
        throw Exception('Chưa được cấp quyền vị trí.');
      }
      if (!await Geolocator.isLocationServiceEnabled())
        throw Exception('Vui lòng bật dịch vụ vị trí.');
      final position = await Geolocator.getCurrentPosition();
      final meters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        plan.latitude,
        plan.longitude,
      );
      if (meters > 150)
        throw Exception(
          'Bạn đang cách điểm đến ${meters.round()} m; cần ở trong bán kính 150 m.',
        );
      if (!await _requestCameraPermission()) {
        throw Exception('Chưa được cấp quyền camera để chụp ảnh check-in.');
      }
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image == null || !mounted) return;
      await ref.read(itineraryRepositoryProvider).checkIn(plan, image);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Check-in thành công!')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    }
  }

  void _showCheckInPhoto(PlacePlan plan) {
    final url = plan.checkInPhotoUrl;
    if (url == null || url.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(
                'Check-in: ${plan.placeName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Không tải được ảnh check-in.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
