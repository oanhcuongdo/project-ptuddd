import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Dịch vụ giải mã địa chỉ đa nền tảng (Android, iOS, Web, Desktop):
/// - Dùng plugin `geocoding` bản địa khi nền tảng có đăng ký `GeocodingPlatformFactory`.
/// - Tự động chuyển sang OpenStreetMap Nominatim (HTTPS/CORS) trên Web/Desktop
///   hoặc khi plugin bản địa không trả về kết quả, tránh lỗi `Unexpected null value`.
class GeocodingHelper {
  GeocodingHelper._();

  static const _headers = {
    'Accept': 'application/json',
    'Accept-Language': 'vi,en;q=0.8',
  };

  static geocoding.Geocoding? _nativeGeocoder() {
    if (geocoding.GeocodingPlatformFactory.instance == null) {
      return null;
    }
    try {
      return geocoding.Geocoding(locale: const Locale('vi', 'VN'));
    } catch (_) {
      return null;
    }
  }

  static String formatPlacemark(geocoding.Placemark p) {
    return [
          p.street,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
          p.country,
        ]
        .whereType<String>()
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .join(', ');
  }

  /// Parse địa chỉ tiếng Việt gọn gàng từ phản hồi JSON của Nominatim.
  static String? parseNominatimReverse(Map<String, dynamic> json) {
    final addr = json['address'];
    if (addr is Map<String, dynamic>) {
      final road = [
        addr['house_number'],
        addr['road'] ?? addr['pedestrian'] ?? addr['neighbourhood'],
      ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).join(' ');

      final parts = <String>{
        if (road.isNotEmpty) road,
        ...[
          addr['suburb'] ?? addr['quarter'] ?? addr['village'],
          addr['city_district'] ?? addr['district'] ?? addr['town'] ?? addr['county'],
          addr['city'] ?? addr['state'] ?? addr['province'],
        ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty),
      }.toList();

      if (parts.isNotEmpty) return parts.join(', ');
    }

    final displayName = json['display_name'];
    if (displayName is String && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    return null;
  }

  /// Parse tọa độ đầu tiên từ phản hồi JSON tìm kiếm của Nominatim.
  static LatLng? parseNominatimSearch(List<dynamic> list) {
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final lat = double.tryParse('${item['lat'] ?? ''}');
      final lon = double.tryParse('${item['lon'] ?? ''}');
      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    }
    return null;
  }

  /// Dịch tọa độ -> địa chỉ (Reverse Geocoding), an toàn trên mọi nền tảng.
  static Future<String?> reverseGeocode(
    double latitude,
    double longitude, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final native = _nativeGeocoder();
    if (native != null) {
      try {
        final places = await native.placemarkFromCoordinates(
          latitude,
          longitude,
        );
        if (places.isNotEmpty) {
          final formatted = formatPlacemark(places.first);
          if (formatted.isNotEmpty) return formatted;
        }
      } catch (_) {
        // Fallback sang Nominatim bên dưới.
      }
    }

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'accept-language': 'vi',
        'zoom': '18',
      });
      final response = await http.get(uri, headers: _headers).timeout(timeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return parseNominatimReverse(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Tìm tọa độ từ tên đường / địa chỉ (Forward Geocoding), an toàn trên mọi nền tảng.
  static Future<LatLng?> searchAddress(
    String query, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    final native = _nativeGeocoder();
    if (native != null) {
      try {
        final matches = await native.locationFromAddress(trimmed);
        if (matches.isNotEmpty) {
          return LatLng(matches.first.latitude, matches.first.longitude);
        }
      } catch (_) {
        // Fallback sang Nominatim bên dưới.
      }
    }

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': trimmed,
        'countrycodes': 'vn',
        'limit': '1',
        'accept-language': 'vi',
      });
      final response = await http.get(uri, headers: _headers).timeout(timeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! List<dynamic>) return null;
      return parseNominatimSearch(decoded);
    } catch (_) {
      return null;
    }
  }
}
