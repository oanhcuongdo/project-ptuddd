import '../entities/favorite_food.dart';
import '../entities/food_item.dart';

abstract class FavoriteRepository {
  /// Món hay ăn, sắp theo lần dùng gần nhất.
  Stream<List<FavoriteFood>> watchFavorites(String uid, {int limit = 20});

  /// Ghi nhận một lần ăn món: tăng `use_count`, cập nhật `last_used_at`.
  void recordUse(String uid, FoodItem item);
}
