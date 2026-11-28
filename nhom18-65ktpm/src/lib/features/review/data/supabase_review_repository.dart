import '../../../core/supabase_client.dart';
import '../../../core/supabase_errors.dart';
import '../../../models/review.dart';
import '../../../repositories/auth_repository.dart';
import '../../../repositories/review_repository.dart';
import '../review_rules.dart';

/// UC-08. rating / review_count của tiệm do trigger `refresh_shop_rating` tự tính lại.
class SupabaseReviewRepository implements ReviewRepository {
  String get _uid {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(
        'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.',
      );
    }
    return id;
  }

  @override
  Future<List<Review>> listByShop(String shopId) {
    return guardSupabase(() async {
      try {
        final rows = await supabase.rpc(
          'get_shop_reviews',
          params: {'p_shop_id': shopId},
        ) as List;
        return rows
            .map((e) => Review.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        // Dự phòng nếu Supabase chưa có RPC get_shop_reviews.
        final rows = await supabase
            .from('reviews')
            .select()
            .eq('shop_id', shopId)
            .order('created_at', ascending: false);
        return rows.map(Review.fromMap).toList();
      }
    });
  }

  /// Đánh giá cũ của rider cho tiệm (để sửa lại), null nếu chưa có.
  Future<Review?> myReview(String shopId) {
    return guardSupabase(() async {
      final row = await supabase
          .from('reviews')
          .select()
          .eq('shop_id', shopId)
          .eq('rider_id', _uid)
          .maybeSingle();
      return row == null ? null : Review.fromMap(row);
    });
  }

  @override
  Future<Review> upsert({
    required String shopId,
    required int rating,
    String? comment,
  }) {
    final error = validateRating(rating) ?? validateReviewComment(comment);
    if (error != null) throw AppException(error);

    return guardSupabase(() async {
      final text = comment?.trim() ?? '';
      // Mỗi rider một đánh giá / tiệm (unique shop_id, rider_id): gửi lại thì cập nhật.
      final row = await supabase
          .from('reviews')
          .upsert({
            'shop_id': shopId,
            'rider_id': _uid,
            'rating': rating,
            'comment': text.isEmpty ? null : text,
          }, onConflict: 'shop_id,rider_id')
          .select()
          .single();
      return Review.fromMap(row);
    });
  }
}
