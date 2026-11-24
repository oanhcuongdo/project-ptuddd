import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/place_model.dart';

class OverpassSearchUnavailableException implements Exception {
  const OverpassSearchUnavailableException();

  @override
  String toString() =>
      'Máy chủ tìm kiếm địa điểm đang quá tải. Vui lòng thử lại sau.';
}

class OverpassHttpException implements Exception {
  const OverpassHttpException(this.statusCode);

  final int statusCode;

  @override
  String toString() =>
      'Overpass phản hồi mã $statusCode. Vui lòng kiểm tra truy vấn rồi thử lại.';
}

class OverpassRepository {
  OverpassRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final Map<String, List<Place>> _cache = {};
  Future<void> _requestQueue = Future<void>.value();
  static const _endpoint = 'https://overpass-api.de/api/interpreter';
  static const _retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
  ];

  Future<List<Place>> search({
    required String query,
    required String area,
    required PlaceCategory category,
  }) async {
    final key =
        '${query.trim().toLowerCase()}|${area.trim().toLowerCase()}|${category.name}';
    if (_cache.containsKey(key)) return _cache[key]!;
    final normalizedArea = area.trim().toLowerCase();
    final center =
        _knownAreas[normalizedArea] ?? _parseCoordinates(normalizedArea);
    if (center == null) {
      throw const FormatException(
        'Chưa nhận diện khu vực. Hãy nhập tên thành phố được hỗ trợ (Hà Nội, TP. Hồ Chí Minh, Đà Nẵng, Huế, Hội An).',
      );
    }
    final safeQuery = query.trim().replaceAll(RegExp(r'["\\]'), ' ');
    final q = safeQuery.replaceAllMapped(
      RegExp(r'([\\.^$|?*+(){}\[\]])'),
      (match) => '\\${match[0]}',
    );
    final filters = _filters(category);
    final searchFilter = q.isEmpty
        ? ''
        : '[name~"${q.substring(0, q.length > 60 ? 60 : q.length)}",i]';
    final statements = filters
        .map(
          (f) =>
              'nwr(around:12000,${center.latitude},${center.longitude})$f$searchFilter;',
        )
        .join('\n');
    final body = '[out:json][timeout:20];($statements);out center tags 60;';
    final previousRequest = _requestQueue;
    final releaseRequest = Completer<void>();
    _requestQueue = releaseRequest.future;
    await previousRequest;

    try {
      // Another queued request may already have populated this cache key.
      final cached = _cache[key];
      if (cached != null) return cached;

      final places = await _fetchWithRetry(body);
      _cache[key] = places;
      return places;
    } finally {
      releaseRequest.complete();
    }
  }

  Future<List<Place>> _fetchWithRetry(String query) async {
    for (var attempt = 0; attempt <= _retryDelays.length; attempt++) {
      try {
        final response = await _client
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'User-Agent': 'TravelBuddy/1.0 (OpenStreetMap Overpass client)',
              },
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 502 ||
            response.statusCode == 503 ||
            response.statusCode == 504) {
          if (attempt < _retryDelays.length) {
            await Future<void>.delayed(_retryDelays[attempt]);
            continue;
          }
          throw const OverpassSearchUnavailableException();
        }
        if (response.statusCode != 200) {
          throw OverpassHttpException(response.statusCode);
        }

        return _parsePlaces(response.bodyBytes);
      } on OverpassSearchUnavailableException {
        rethrow;
      } on OverpassHttpException {
        rethrow;
      } on Object catch (error) {
        if (!_isTransientConnectionError(error)) rethrow;
        if (attempt >= _retryDelays.length) {
          throw const OverpassSearchUnavailableException();
        }
        await Future<void>.delayed(_retryDelays[attempt]);
      }
    }

    throw const OverpassSearchUnavailableException();
  }

  List<Place> _parsePlaces(List<int> bodyBytes) {
    final decoded = jsonDecode(utf8.decode(bodyBytes));
    if (decoded is! Map || decoded['elements'] is! List) {
      throw const FormatException('Dữ liệu địa điểm trả về không hợp lệ.');
    }
    final places = <Place>[];
    for (final raw in decoded['elements'] as List) {
      if (raw is! Map) continue;
      final tags = raw['tags'];
      if (tags is! Map) continue;
      final lat = (raw['lat'] ?? raw['center']?['lat']) as num?;
      final lon = (raw['lon'] ?? raw['center']?['lon']) as num?;
      final name = tags['name']?.toString().trim();
      if (lat == null || lon == null || name == null || name.isEmpty) continue;
      final address = [
        tags['addr:street'],
        tags['addr:city'],
      ].whereType<String>().where((v) => v.isNotEmpty).join(', ');
      places.add(
        Place(
          id: '${raw['type']}/${raw['id']}',
          name: name,
          category: PlaceCategory.fromTags(Map<String, dynamic>.from(tags)),
          location: LatLng(lat.toDouble(), lon.toDouble()),
          address: address.isEmpty ? null : address,
          description: tags['description']?.toString(),
        ),
      );
    }
    places.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return places;
  }

  bool _isTransientConnectionError(Object error) =>
      error is TimeoutException ||
      error is SocketException ||
      error is HandshakeException ||
      error is http.ClientException;

  List<String> _filters(PlaceCategory category) {
    final all = <String>[
      r'[tourism~"^(attraction|museum|viewpoint|gallery|hotel|guest_house|hostel)$"]',
      r'[amenity~"^(restaurant|fast_food|food_court|cafe|cinema|theatre|arts_centre)$"]',
      r'[leisure~"^(park|amusement_arcade)$"]',
    ];
    switch (category) {
      case PlaceCategory.all:
        return all;
      case PlaceCategory.attraction:
        return [r'[tourism~"^(attraction|museum|viewpoint|gallery)$"]'];
      case PlaceCategory.restaurant:
        return [r'[amenity~"^(restaurant|fast_food|food_court)$"]'];
      case PlaceCategory.cafe:
        return ['[amenity=cafe]'];
      case PlaceCategory.lodging:
        return [r'[tourism~"^(hotel|guest_house|hostel)$"]'];
      case PlaceCategory.entertainment:
        return [
          r'[amenity~"^(cinema|theatre|arts_centre)$"]',
          r'[leisure~"^(park|amusement_arcade)$"]',
        ];
    }
  }

  LatLng? _parseCoordinates(String value) {
    final match = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*[,; ]\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(value);
    if (match == null) return null;
    final latitude = double.tryParse(match.group(1)!);
    final longitude = double.tryParse(match.group(2)!);
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  static const _knownAreas = <String, LatLng>{
    'hà nội': LatLng(21.0285, 105.8542),
    'ha noi': LatLng(21.0285, 105.8542),
    'hồ chí minh': LatLng(10.7769, 106.7009),
    'ho chi minh': LatLng(10.7769, 106.7009),
    'tp. hồ chí minh': LatLng(10.7769, 106.7009),
    'sài gòn': LatLng(10.7769, 106.7009),
    'đà nẵng': LatLng(16.0544, 108.2022),
    'da nang': LatLng(16.0544, 108.2022),
    'huế': LatLng(16.4637, 107.5909),
    'hue': LatLng(16.4637, 107.5909),
    'hội an': LatLng(15.8801, 108.3380),
    'hoi an': LatLng(15.8801, 108.3380),
  };

  void dispose() => _client.close();
}
