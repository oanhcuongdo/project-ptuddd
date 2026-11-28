import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_plan.dart';
import '../models/place_suggestion.dart';

class PlaceDiscoveryRepository {
  static const Map<String, ({double lat, double lon})> _knownDestinations = {
    'đà lạt': (lat: 11.9404, lon: 108.4583),
    'da lat': (lat: 11.9404, lon: 108.4583),
    'đà nẵng': (lat: 16.0544, lon: 108.2022),
    'da nang': (lat: 16.0544, lon: 108.2022),
    'hội an': (lat: 15.8801, lon: 108.3380),
    'hoi an': (lat: 15.8801, lon: 108.3380),
    'nha trang': (lat: 12.2388, lon: 109.1967),
    'phú quốc': (lat: 10.2899, lon: 103.9840),
    'phu quoc': (lat: 10.2899, lon: 103.9840),
    'sa pa': (lat: 22.3364, lon: 103.8438),
    'sapa': (lat: 22.3364, lon: 103.8438),
    'hà nội': (lat: 21.0285, lon: 105.8542),
    'ha noi': (lat: 21.0285, lon: 105.8542),
    'vũng tàu': (lat: 10.4114, lon: 107.1362),
    'vung tau': (lat: 10.4114, lon: 107.1362),
    'huế': (lat: 16.4637, lon: 107.5909),
    'hue': (lat: 16.4637, lon: 107.5909),
    'ninh bình': (lat: 20.2506, lon: 105.9745),
    'ninh binh': (lat: 20.2506, lon: 105.9745),
    'quy nhơn': (lat: 13.7830, lon: 109.2197),
    'quy nhon': (lat: 13.7830, lon: 109.2197),
    'cần thơ': (lat: 10.0452, lon: 105.7469),
    'can tho': (lat: 10.0452, lon: 105.7469),
    'hồ chí minh': (lat: 10.7769, lon: 106.7009),
    'ho chi minh': (lat: 10.7769, lon: 106.7009),
    'sài gòn': (lat: 10.7769, lon: 106.7009),
  };

  bool lastSearchUsedFallback = false;

  /// Resolves approximate `(latitude, longitude)` for a destination name.
  Future<({double lat, double lon})?> resolveDestinationCoordinates(
    String destinationName,
  ) async {
    final normalized = destinationName.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final entry in _knownDestinations.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': destinationName.trim(),
        'format': 'json',
        'limit': '1',
      });
      final response = await http
          .get(uri, headers: {'User-Agent': 'TravelBuddyApp/1.0'})
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        if (decoded.isNotEmpty) {
          final first = decoded.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            return (lat: lat, lon: lon);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<PlaceSuggestion>> search({
    String query = '',
    PlaceCategory? category,
    double latitude = 16.0544,
    double longitude = 108.2022,
    String? destinationName,
  }) async {
    var targetLat = latitude;
    var targetLon = longitude;
    if (destinationName != null && destinationName.trim().isNotEmpty) {
      final resolved = await resolveDestinationCoordinates(destinationName);
      if (resolved != null) {
        targetLat = resolved.lat;
        targetLon = resolved.lon;
      }
    }
    try {
      final tags = category == PlaceCategory.food
          ? ['amenity=restaurant', 'amenity=cafe']
          : category == PlaceCategory.hotel
          ? ['tourism=hotel']
          : ['tourism=attraction', 'tourism=museum', 'historic=monument'];
      final clauses = tags
          .map((tag) => 'nwr["$tag"](around:12000,$targetLat,$targetLon);')
          .join();
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            body: {
              'data': '[out:json][timeout:15];($clauses);out center tags;',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final elements =
            (jsonDecode(response.body)['elements'] as List<dynamic>);
        final result = elements
            .map(_fromOverpass)
            .whereType<PlaceSuggestion>()
            .where((item) {
              return query.trim().isEmpty ||
                  item.name.toLowerCase().contains(query.toLowerCase());
            })
            .take(50)
            .toList();
        if (result.isNotEmpty) {
          lastSearchUsedFallback = false;
          return result;
        }
      }
    } catch (_) {}
    lastSearchUsedFallback = true;
    return fallback(
      category,
      query,
      destinationName: destinationName,
      latitude: targetLat,
      longitude: targetLon,
    );
  }

  PlaceSuggestion? _fromOverpass(dynamic raw) {
    final tags = Map<String, dynamic>.from(raw['tags'] as Map? ?? {});
    final name = tags['name'] as String?;
    final center = raw['center'] as Map?;
    final lat = (raw['lat'] ?? center?['lat']) as num?;
    final lon = (raw['lon'] ?? center?['lon']) as num?;
    if (name == null || lat == null || lon == null) return null;
    final category = tags['amenity'] != null
        ? PlaceCategory.food
        : tags['tourism'] == 'hotel'
        ? PlaceCategory.hotel
        : PlaceCategory.attraction;
    return PlaceSuggestion(
      id: '${raw['type']}_${raw['id']}',
      name: name,
      category: category,
      address: tags['addr:street'] as String? ?? '',
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      defaultDurationMinutes: category == PlaceCategory.hotel ? 30 : 90,
    );
  }

  /// Generates destination-aware offline suggestions without hardcoded city presets.
  List<PlaceSuggestion> fallback(
    PlaceCategory? category,
    String query, {
    String? destinationName,
    double latitude = 16.0544,
    double longitude = 108.2022,
  }) {
    final dest = (destinationName == null || destinationName.trim().isEmpty)
        ? 'điểm đến'
        : destinationName.trim();
    final items = [
      PlaceSuggestion(
        id: 'fallback-attraction',
        name: 'Điểm tham quan nổi bật $dest',
        category: PlaceCategory.attraction,
        address: 'Khu vực trung tâm $dest',
        latitude: latitude,
        longitude: longitude,
        defaultDurationMinutes: 90,
        rating: 4.5,
      ),
      PlaceSuggestion(
        id: 'fallback-food',
        name: 'Đặc sản địa phương $dest',
        category: PlaceCategory.food,
        address: 'Khu ẩm thực $dest',
        latitude: latitude + 0.004,
        longitude: longitude + 0.004,
        defaultDurationMinutes: 75,
        estimatedFoodCost: 150000,
        rating: 4.4,
      ),
      PlaceSuggestion(
        id: 'fallback-hotel',
        name: 'Lưu trú trung tâm $dest',
        category: PlaceCategory.hotel,
        address: 'Trung tâm $dest',
        latitude: latitude - 0.003,
        longitude: longitude - 0.003,
        defaultDurationMinutes: 30,
        estimatedFoodCost: 0,
        rating: 4.2,
      ),
    ];
    return items
        .where(
          (item) =>
              (category == null || item.category == category) &&
              (query.isEmpty ||
                  item.name.toLowerCase().contains(query.toLowerCase()) ||
                  item.address.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
  }
}
