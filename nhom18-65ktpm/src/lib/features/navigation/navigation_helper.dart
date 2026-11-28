import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Một chặng chỉ dẫn rẽ theo tuyến đường bộ thực tế (từ OSRM steps).
class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.maneuverType,
    this.modifier,
    this.roadName = '',
  });

  final String instruction;
  final double distanceMeters;
  final String maneuverType;
  final String? modifier;
  final String roadName;
}

/// Thông tin tuyến đường bộ thực tế (từ OSRM) hoặc đường thẳng ước tính (UC-06).
class RouteInfo {
  const RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationMinutes,
    required this.isRoadRoute,
    this.steps = const [],
  });

  final List<LatLng> points;
  final double distanceMeters;
  final int durationMinutes;
  final bool isRoadRoute;
  final List<RouteStep> steps;
}

/// Hỗ trợ UC-06: Chỉ đường (Navigation) theo tuyến đường bộ thực tế trên mọi nền tảng
/// (Web/Chrome, Android, iOS, Desktop) qua `package:http` và cụm máy chủ OSRM công khai.
class NavigationHelper {
  NavigationHelper._();

  static const _headers = {'Accept': 'application/json'};

  /// Danh sách máy chủ OSRM dự phòng (cùng chuẩn GeoJSON, hỗ trợ CORS cho Web).
  static List<Uri> buildOsrmUris({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
  }) {
    final coords = '$originLng,$originLat;$destinationLng,$destinationLat';
    const query = {
      'overview': 'full',
      'geometries': 'geojson',
      'steps': 'true',
    };
    return [
      Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/$coords',
        query,
      ),
      Uri.https(
        'routing.openstreetmap.de',
        '/routed-car/route/v1/driving/$coords',
        query,
      ),
      Uri.https(
        'routing.openstreetmap.de',
        '/routed-bike/route/v1/driving/$coords',
        query,
      ),
    ];
  }

  /// Chuyển thao tác rẽ OSRM thành chỉ dẫn tiếng Việt tự nhiên.
  static String formatStepInstruction({
    required String type,
    String? modifier,
    required String roadName,
  }) {
    final road = roadName.trim();
    final onRoad = road.isNotEmpty ? ' trên $road' : '';
    final intoRoad = road.isNotEmpty ? ' vào $road' : '';

    if (type == 'depart') return 'Xuất phát$onRoad';
    if (type == 'arrive') return 'Đã đến điểm đích';
    if (type == 'roundabout' || type == 'rotary') {
      return 'Đi qua vòng xuyến$intoRoad';
    }
    if (type == 'merge') return 'Nhập làn$intoRoad';
    if (type == 'fork') {
      return switch (modifier) {
        'left' || 'slight left' => 'Đi theo nhánh trái$intoRoad',
        'right' || 'slight right' => 'Đi theo nhánh phải$intoRoad',
        _ => 'Tiếp tục đi thẳng$intoRoad',
      };
    }

    return switch (modifier) {
      'uturn' => 'Quay đầu$intoRoad',
      'sharp left' => 'Rẽ ngoặt trái$intoRoad',
      'left' => 'Rẽ trái$intoRoad',
      'slight left' => 'Chếch sang trái$intoRoad',
      'sharp right' => 'Rẽ ngoặt phải$intoRoad',
      'right' => 'Rẽ phải$intoRoad',
      'slight right' => 'Chếch sang phải$intoRoad',
      _ => road.isNotEmpty ? 'Đi thẳng theo $road' : 'Tiếp tục đi thẳng',
    };
  }

  /// Phân tích phản hồi JSON của OSRM Route API (GeoJSON + steps).
  static RouteInfo? parseOsrmRoute(Map<String, dynamic> json) {
    final routes = json['routes'];
    if (routes is! List || routes.isEmpty) return null;
    final first = routes.first;
    if (first is! Map<String, dynamic>) return null;

    final geometry = first['geometry'];
    if (geometry is! Map<String, dynamic>) return null;
    final coords = geometry['coordinates'];
    if (coords is! List || coords.length < 2) return null;

    final points = <LatLng>[];
    for (final item in coords) {
      if (item is List && item.length >= 2 && item[0] is num && item[1] is num) {
        // GeoJSON trả [longitude, latitude]
        points.add(
          LatLng((item[1] as num).toDouble(), (item[0] as num).toDouble()),
        );
      }
    }
    if (points.length < 2) return null;

    final steps = <RouteStep>[];
    final legs = first['legs'];
    if (legs is List) {
      for (final leg in legs) {
        if (leg is! Map<String, dynamic>) continue;
        final rawSteps = leg['steps'];
        if (rawSteps is! List) continue;
        for (final raw in rawSteps) {
          if (raw is! Map<String, dynamic>) continue;
          final maneuver = raw['maneuver'];
          final type =
              maneuver is Map<String, dynamic> ? '${maneuver['type'] ?? ''}' : '';
          final modifier = maneuver is Map<String, dynamic>
              ? maneuver['modifier'] as String?
              : null;
          final roadName = '${raw['name'] ?? ''}'.trim();
          final dist = (raw['distance'] as num?)?.toDouble() ?? 0;
          if (type.isEmpty) continue;
          steps.add(
            RouteStep(
              instruction: formatStepInstruction(
                type: type,
                modifier: modifier,
                roadName: roadName,
              ),
              distanceMeters: dist,
              maneuverType: type,
              modifier: modifier,
              roadName: roadName,
            ),
          );
        }
      }
    }

    final distanceMeters = (first['distance'] as num?)?.toDouble() ?? 0;
    final durationSeconds = (first['duration'] as num?)?.toDouble() ?? 0;
    final minutes = durationSeconds > 0
        ? math.max(1, (durationSeconds / 60).ceil())
        : estimateMotorbikeMinutes(distanceMeters);

    return RouteInfo(
      points: points,
      distanceMeters: distanceMeters,
      durationMinutes: minutes,
      isRoadRoute: true,
      steps: steps,
    );
  }

  /// Lấy tuyến đường bộ thực tế qua cụm máy chủ OSRM công khai (miễn phí, không cần key,
  /// chạy ổn định trên cả Flutter Web/Chrome lẫn Android/iOS).
  /// Trả `null` nếu mọi máy chủ đều không kết nối được để màn hình dùng dự phòng.
  static Future<RouteInfo?> fetchRoadRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    Duration timeout = const Duration(seconds: 9),
    http.Client? client,
  }) async {
    final uris = buildOsrmUris(
      originLat: originLat,
      originLng: originLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    );
    final httpClient = client ?? http.Client();
    final ownsClient = client == null;

    try {
      for (final uri in uris) {
        try {
          final response = await httpClient
              .get(uri, headers: _headers)
              .timeout(timeout);
          if (response.statusCode != 200) continue;

          final decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic>) continue;
          final route = parseOsrmRoute(decoded);
          if (route != null) return route;
        } catch (_) {
          // Thử máy chủ OSRM dự phòng kế tiếp.
        }
      }
      return null;
    } finally {
      if (ownsClient) httpClient.close();
    }
  }

  /// Mở ứng dụng Google Maps ngoài để điều hướng rẽ theo từng chặng (Turn-by-turn navigation)
  static Future<bool> openExternalGoogleMaps({
    required double destinationLat,
    required double destinationLng,
    BuildContext? context,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=driving',
    );

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể mở ứng dụng bản đồ Google Maps.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return false;
      }
    } catch (_) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi mở bản đồ bên ngoài.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return false;
    }
  }

  /// Tính khoảng cách giữa 2 tọa độ (mét)
  static double calculateDistanceMeters({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Định dạng khoảng cách thân thiện: "450 m" hoặc "3.2 km"
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Ước tính thời gian di chuyển bằng xe máy trong đô thị (~28 km/h)
  /// Cộng thêm hệ số đường cong thực tế ~1.25 so với khoảng cách chim bay
  static int estimateMotorbikeMinutes(double straightMeters) {
    final roadMeters = straightMeters * 1.25;
    final km = roadMeters / 1000.0;
    final hours = km / 28.0;
    final minutes = (hours * 60).ceil();
    return math.max(1, minutes);
  }

  /// Định dạng chuỗi thời gian di chuyển: "5 phút", "1 giờ 10 phút"
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes phút';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours giờ';
    }
    return '$hours giờ $remainingMinutes phút';
  }
}
