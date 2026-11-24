import 'package:latlong2/latlong.dart';

enum PlaceCategory {
  all('Tất cả', ''),
  attraction('Tham quan', 'attraction'),
  restaurant('Nhà hàng', 'restaurant'),
  cafe('Quán cà phê', 'cafe'),
  lodging('Lưu trú', 'lodging'),
  entertainment('Vui chơi', 'entertainment');

  const PlaceCategory(this.label, this.overpassValue);
  final String label;
  final String overpassValue;

  static PlaceCategory fromTags(Map<String, dynamic> tags) {
    final tourism = tags['tourism']?.toString();
    if (tourism == 'hotel' || tourism == 'guest_house' || tourism == 'hostel') {
      return lodging;
    }
    if (tourism == 'museum' ||
        tourism == 'attraction' ||
        tourism == 'viewpoint' ||
        tourism == 'gallery') {
      return attraction;
    }
    final amenity = tags['amenity']?.toString();
    if (amenity == 'restaurant' ||
        amenity == 'fast_food' ||
        amenity == 'food_court') {
      return restaurant;
    }
    if (amenity == 'cafe') return cafe;
    if (amenity == 'cinema' ||
        amenity == 'theatre' ||
        amenity == 'arts_centre' ||
        tags['leisure'] == 'park' ||
        tags['leisure'] == 'amusement_arcade') {
      return entertainment;
    }
    if (tourism != null) return lodging;
    return attraction;
  }
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    this.address,
    this.description,
  });

  final String id;
  final String name;
  final PlaceCategory category;
  final LatLng location;
  final String? address;
  final String? description;
}

class ItineraryStop {
  const ItineraryStop({
    required this.id,
    required this.place,
    required this.date,
    required this.start,
    required this.end,
    required this.cost,
    this.note = '',
    this.checkedInAt,
    this.checkInLocation,
    this.photoPath,
  });

  final String id;
  final Place place;
  final DateTime date;
  final String start;
  final String end;
  final double cost;
  final String note;
  final DateTime? checkedInAt;
  final LatLng? checkInLocation;
  final String? photoPath;

  int get durationMinutes {
    final s = _minuteOfDay(start);
    final e = _minuteOfDay(end);
    return s == null || e == null ? 0 : e - s;
  }

  ItineraryStop copyWith({
    String? start,
    String? end,
    DateTime? date,
    double? cost,
    String? note,
    DateTime? checkedInAt,
    LatLng? checkInLocation,
    String? photoPath,
  }) => ItineraryStop(
    id: id,
    place: place,
    date: date ?? this.date,
    start: start ?? this.start,
    end: end ?? this.end,
    cost: cost ?? this.cost,
    note: note ?? this.note,
    checkedInAt: checkedInAt ?? this.checkedInAt,
    checkInLocation: checkInLocation ?? this.checkInLocation,
    photoPath: photoPath ?? this.photoPath,
  );
}

int? _minuteOfDay(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour > 23 || minute > 59) return null;
  return hour * 60 + minute;
}
