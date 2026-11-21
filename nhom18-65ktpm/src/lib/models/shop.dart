/// Tiệm sửa xe / cây xăng, tương ứng bảng `public.shops`.
class Shop {
  const Shop({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
    required this.rating,
    required this.reviewCount,
    required this.status,
    this.imageUrl,
    this.createdAt,
    this.distanceM,
  });

  final String id;
  final String ownerId;
  final String name;

  /// repair_shop | gas_station
  final String category;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;

  /// Dạng "07:00:00" từ Postgres.
  final String openTime;
  final String closeTime;
  final bool isOpen;
  final String? imageUrl;
  final double rating;
  final int reviewCount;

  /// pending | approved | rejected | banned
  final String status;
  final DateTime? createdAt;

  /// Chỉ có khi lấy từ RPC `get_nearby_shops`.
  final double? distanceM;

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'].toString(),
      ownerId: map['owner_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'repair_shop',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      openTime: map['open_time']?.toString() ?? '00:00:00',
      closeTime: map['close_time']?.toString() ?? '23:59:00',
      isOpen: map['is_open'] as bool? ?? false,
      imageUrl: map['image_url']?.toString(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      distanceM: (map['distance_m'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'name': name,
      'category': category,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'open_time': openTime,
      'close_time': closeTime,
      'is_open': isOpen,
      'image_url': imageUrl,
    };
  }
}
