import '../models/review.dart';

/// Hợp đồng cho UC-04 (hiển thị review) và UC-08 (viết review).
/// Quân tạo `SupabaseReviewRepository` trong module review/.
abstract class ReviewRepository {
  Future<List<Review>> listByShop(String shopId);

  /// Mỗi rider một review/tiệm: insert hoặc update bản ghi cũ.
  Future<Review> upsert({
    required String shopId,
    required int rating,
    String? comment,
  });
}
