import '../core/constants/app_config.dart';
import '../core/result.dart';
import '../core/strings/diary_strings.dart';
import '../domain/entities/food_item.dart';
import '../domain/entities/meal.dart';
import '../domain/enums.dart';
import '../domain/repositories/favorite_repository.dart';
import '../domain/repositories/meal_repository.dart';
import 'meal_events.dart';
import 'session_service.dart';

/// Lưu bữa ăn SAU KHI người dùng nhấn "Lưu" ở màn hình xác nhận.
///
/// - Bữa mới: tạo meal + cập nhật "món hay ăn" (favorites) cho từng món.
/// - Bữa cũ (có [existingId]): cập nhật meal.
/// - Báo [MealEvents] để các phân hệ khác (thử thách) tính lại.
class ConfirmAndSaveMeal {
  ConfirmAndSaveMeal(this._meals, this._favorites, this._session, this._events);

  final MealRepository _meals;
  final FavoriteRepository _favorites;
  final SessionService _session;
  final MealEvents _events;

  Result<String> call({
    required List<FoodItem> items,
    required MealType mealType,
    required DateTime eatenAt,
    required InputMethod inputMethod,
    bool userEdited = false,
    String? existingId,
  }) {
    final cleaned = items
        .map((i) => i.copyWith(
              name: i.name.trim(),
              shortNote: _truncate(i.shortNote.trim(), AppConfig.shortNoteMaxLength),
            ))
        .where((i) => i.name.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      return const Err(AppFailure(FailureType.invalidResponse, ReviewStrings.selectAtLeastOne));
    }
    if (cleaned.length > 10) {
      return const Err(AppFailure(FailureType.invalidResponse, ReviewStrings.tooManyItems));
    }

    final uid = _session.uid;
    final meal = Meal(
      id: existingId,
      eatenAt: eatenAt.toUtc(),
      mealType: mealType,
      inputMethod: inputMethod,
      items: cleaned,
      userEdited: userEdited,
    );

    final String id;
    if (existingId == null) {
      id = _meals.addMeal(uid, meal);
      for (final item in cleaned) {
        _favorites.recordUse(uid, item);
      }
    } else {
      _meals.updateMeal(uid, meal);
      id = existingId;
    }
    _events.notifyChanged();
    return Ok(id);
  }

  static String _truncate(String text, int max) =>
      text.length <= max ? text : text.substring(0, max);
}
