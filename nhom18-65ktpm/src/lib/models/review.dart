/// Đánh giá dịch vụ, tương ứng bảng `public.reviews`.
class Review {
  const Review({
    required this.id,
    required this.shopId,
    required this.riderId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String shopId;
  final String riderId;

  /// 1..5
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'].toString(),
      shopId: map['shop_id']?.toString() ?? '',
      riderId: map['rider_id']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      comment: map['comment']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shop_id': shopId,
      'rider_id': riderId,
      'rating': rating,
      'comment': comment,
    };
  }
}
