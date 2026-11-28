import '../core/constants/app_config.dart';
import '../domain/entities/favorite_food.dart';
import '../domain/entities/meal.dart';
import '../domain/repositories/favorite_repository.dart';
import '../domain/repositories/meal_repository.dart';
import '../domain/rules/vn_calendar.dart';
import 'session_service.dart';

/// Các truy vấn đọc nhật ký cho giao diện (realtime bằng Stream).
class MealQueries {
  MealQueries(this._meals, this._favorites, this._session);

  final MealRepository _meals;
  final FavoriteRepository _favorites;
  final SessionService _session;

  /// Bữa ăn của một ngày (theo lịch Việt Nam).
  Stream<List<Meal>> watchDay(DateTime vnDate) {
    final range = VnCalendar.dayRangeUtc(vnDate);
    return _meals.watchMealsBetween(_session.uid, range.start, range.end);
  }

  /// Bữa ăn trong khoảng [startUtc, endUtc).
  Stream<List<Meal>> watchBetween(DateTime startUtc, DateTime endUtc) =>
      _meals.watchMealsBetween(_session.uid, startUtc, endUtc);

  Stream<List<Meal>> watchRecent({int limit = 3}) =>
      _meals.watchRecentMeals(_session.uid, limit: limit);

  Stream<List<FavoriteFood>> watchFavorites() =>
      _favorites.watchFavorites(_session.uid, limit: AppConfig.relogListLimit);
}
