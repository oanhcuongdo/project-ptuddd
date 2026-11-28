import '../../../core/supabase_client.dart';
import '../../../models/review.dart';
import '../../../repositories/review_repository.dart';

/// Triển khai ReviewRepository qua Supabase REST API (UC-04 & UC-08).
class SupabaseReviewRepository implements ReviewRepository {
  @override
  Future<List<Review>> listByShop(String shopId) async {
    final res = await supabase
        .from('reviews')
        .select()
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => Review.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<Review> upsert({
    required String shopId,
    required int rating,
    String? comment,
  }) async {
    final riderId = supabase.auth.currentUser?.id;
    if (riderId == null) {
      throw StateError('Bạn cần đăng nhập để gửi đánh giá.');
    }

    final trimmed = comment?.trim();
    final data = {
      'shop_id': shopId,
      'rider_id': riderId,
      'rating': rating,
      'comment': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    };

    final res = await supabase
        .from('reviews')
        .upsert(data, onConflict: 'shop_id,rider_id')
        .select()
        .single();

    return Review.fromMap(Map<String, dynamic>.from(res));
  }
}
