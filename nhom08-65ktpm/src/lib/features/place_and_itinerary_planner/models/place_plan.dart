import 'package:cloud_firestore/cloud_firestore.dart';

enum PlaceCategory { attraction, food, hotel }

class PlacePlan {
  final String id;
  final String tripId;
  final int dayNumber;
  final int sortOrder;
  final String placeName;
  final PlaceCategory category;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime startTime;
  final int durationMinutes;
  final double ticketCost;
  final double foodCost;
  final bool isCheckedIn;
  final DateTime? checkedInAt;
  final String? checkInPhotoUrl;

  const PlacePlan({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    required this.sortOrder,
    required this.placeName,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.address = '',
    required this.startTime,
    this.durationMinutes = 60,
    this.ticketCost = 0,
    this.foodCost = 0,
    this.isCheckedIn = false,
    this.checkedInAt,
    this.checkInPhotoUrl,
  });

  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));
  double get totalEstimatedCost => ticketCost + foodCost;

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static DateTime? _optionalDate(dynamic value) =>
      value == null ? null : _date(value);

  factory PlacePlan.fromMap(Map<String, dynamic> map, {String? id}) {
    final category = PlaceCategory.values.firstWhere(
      (item) => item.name == (map['category'] as String? ?? 'attraction'),
      orElse: () => PlaceCategory.attraction,
    );
    return PlacePlan(
      id: id ?? map['id'] as String? ?? '',
      tripId: map['tripId'] as String? ?? '',
      dayNumber: (map['dayNumber'] as num?)?.toInt() ?? 1,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      placeName: map['placeName'] as String? ?? '',
      category: category,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      address: map['address'] as String? ?? '',
      startTime: _date(map['startTime']),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 60,
      ticketCost: (map['ticketCost'] as num?)?.toDouble() ?? 0,
      foodCost: (map['foodCost'] as num?)?.toDouble() ?? 0,
      isCheckedIn: map['isCheckedIn'] as bool? ?? false,
      checkedInAt: _optionalDate(map['checkedInAt']),
      checkInPhotoUrl: map['checkInPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'tripId': tripId,
    'dayNumber': dayNumber,
    'sortOrder': sortOrder,
    'placeName': placeName,
    'category': category.name,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'startTime': Timestamp.fromDate(startTime),
    'durationMinutes': durationMinutes,
    'ticketCost': ticketCost,
    'foodCost': foodCost,
    'isCheckedIn': isCheckedIn,
    'checkedInAt': checkedInAt == null
        ? null
        : Timestamp.fromDate(checkedInAt!),
    'checkInPhotoUrl': checkInPhotoUrl,
  };

  PlacePlan copyWith({
    int? dayNumber,
    int? sortOrder,
    String? placeName,
    PlaceCategory? category,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? startTime,
    int? durationMinutes,
    double? ticketCost,
    double? foodCost,
    bool? isCheckedIn,
    DateTime? checkedInAt,
    String? checkInPhotoUrl,
  }) => PlacePlan(
    id: id,
    tripId: tripId,
    dayNumber: dayNumber ?? this.dayNumber,
    sortOrder: sortOrder ?? this.sortOrder,
    placeName: placeName ?? this.placeName,
    category: category ?? this.category,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    address: address ?? this.address,
    startTime: startTime ?? this.startTime,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    ticketCost: ticketCost ?? this.ticketCost,
    foodCost: foodCost ?? this.foodCost,
    isCheckedIn: isCheckedIn ?? this.isCheckedIn,
    checkedInAt: checkedInAt ?? this.checkedInAt,
    checkInPhotoUrl: checkInPhotoUrl ?? this.checkInPhotoUrl,
  );
}
