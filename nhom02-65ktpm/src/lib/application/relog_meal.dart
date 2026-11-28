import '../core/result.dart';
import '../domain/entities/favorite_food.dart';
import '../domain/entities/food_item.dart';
import '../domain/enums.dart';
import '../domain/rules/meal_type_rules.dart';
import 'confirm_and_save_meal.dart';
import 'tip_resolver.dart';

/// "Ăn lại": ghi nhanh một món hay ăn thành bữa mới (1 chạm).
class RelogMeal {
  RelogMeal(this._save, this._tips);

  final ConfirmAndSaveMeal _save;
  final TipResolver _tips;

  /// Chuyển món hay ăn thành [FoodItem] kèm gợi ý theo mục tiêu hiện tại.
  FoodItem toItem(FavoriteFood favorite) {
    final item = FoodItem(
      name: favorite.name,
      category: favorite.category,
      levels: favorite.levels,
    );
    return item.copyWith(tips: _tips.forManualItem(item));
  }

  Result<String> call(FavoriteFood favorite, {DateTime? now}) {
    final eatenAt = (now ?? DateTime.now()).toUtc();
    return _save(
      items: [toItem(favorite)],
      mealType: MealTypeRules.defaultFor(eatenAt),
      eatenAt: eatenAt,
      inputMethod: InputMethod.relog,
    );
  }
}
