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
    double latitude = 10.7769,
    double longitude = 106.7009,
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
          .timeout(const Duration(seconds: 18));
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
        if (result.isNotEmpty) return result;
      }
    } catch (_) {}
    return fallback(category, query);
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

  List<PlaceSuggestion> fallback(PlaceCategory? category, String query) {
    const items = [
      PlaceSuggestion(
        id: 'fallback-1',
        name: 'Bảo tàng Chứng tích Chiến tranh',
        category: PlaceCategory.attraction,
        address: '28 Võ Văn Tần, Quận 3',
        latitude: 10.7794,
        longitude: 106.6922,
        defaultDurationMinutes: 90,
        rating: 4.5,
      ),
      PlaceSuggestion(
        id: 'fallback-2',
        name: 'Chợ Bến Thành',
        category: PlaceCategory.food,
        address: 'Lê Lợi, Quận 1',
        latitude: 10.7725,
        longitude: 106.6980,
        defaultDurationMinutes: 90,
        estimatedFoodCost: 120000,
        rating: 4.2,
      ),
      PlaceSuggestion(
        id: 'fallback-3',
        name: 'Khách sạn trung tâm',
        category: PlaceCategory.hotel,
        address: 'Quận 1, TP. Hồ Chí Minh',
        latitude: 10.7750,
        longitude: 106.7000,
        defaultDurationMinutes: 30,
        estimatedFoodCost: 0,
        rating: 4.0,
      ),
    ];
    return items
        .where(
          (item) =>
              (category == null || item.category == category) &&
              (query.isEmpty ||
                  item.name.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
  }
}
