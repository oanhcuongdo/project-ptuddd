import '../entities/meal.dart';

/// Hợp đồng truy cập nhật ký ăn uống.
///
/// Mọi hàm đọc nhật ký/thống kê chỉ trả về bữa có `is_deleted == false`,
/// trừ [watchDeletedMeals] dùng cho Thùng rác.
abstract class MealRepository {
  /// Bữa ăn có `eaten_at` trong [startUtc, endUtc), mới nhất trước.
  Stream<List<Meal>> watchMealsBetween(String uid, DateTime startUtc, DateTime endUtc);

  Future<List<Meal>> getMealsBetween(String uid, DateTime startUtc, DateTime endUtc);

  Stream<List<Meal>> watchRecentMeals(String uid, {int limit = 3});

  Stream<List<Meal>> watchDeletedMeals(String uid);

  /// Trả về id của bữa mới.
  String addMeal(String uid, Meal meal);

  void updateMeal(String uid, Meal meal);

  void softDelete(String uid, String mealId);

  void restore(String uid, String mealId);

  void deletePermanently(String uid, String mealId);
}
