/// Các enum của tầng Domain (Dart thuần).
///
/// Mỗi giá trị có `value` là chuỗi snake_case được LƯU trong Firestore và
/// dùng trong JSON schema của Gemini. Tên trong Dart dùng lowerCamelCase
/// theo chuẩn Dart (ví dụ `Goal.weightLoss` <-> "weight_loss").
library;

/// Giao diện chung cho enum có giá trị lưu trữ dạng chuỗi.
abstract interface class WireEnum {
  String get value;
}

/// Đọc enum từ chuỗi; trả về [fallback] nếu chuỗi không hợp lệ.
T parseWire<T extends WireEnum>(List<T> values, Object? raw, T fallback) {
  return tryParseWire(values, raw) ?? fallback;
}

/// Đọc enum từ chuỗi; trả về null nếu chuỗi không hợp lệ.
T? tryParseWire<T extends WireEnum>(List<T> values, Object? raw) {
  if (raw is! String) return null;
  final normalized = raw.trim().toLowerCase();
  for (final v in values) {
    if (v.value == normalized) return v;
  }
  return null;
}

/// Mức độ tương đối, dùng cho mọi thuộc tính đánh giá món ăn.
enum Level implements WireEnum {
  low('low'),
  medium('medium'),
  high('high');

  const Level(this.value);
  @override
  final String value;

  static List<String> get wireValues => values.map((e) => e.value).toList();
}

enum Goal implements WireEnum {
  weightLoss('weight_loss'),
  balanced('balanced'),
  lessSugar('less_sugar');

  const Goal(this.value);
  @override
  final String value;
}

enum MealType implements WireEnum {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner'),
  snack('snack');

  const MealType(this.value);
  @override
  final String value;
}

enum InputMethod implements WireEnum {
  photo('photo'),
  menu('menu'),
  manual('manual'),
  relog('relog');

  const InputMethod(this.value);
  @override
  final String value;
}

enum FoodCategory implements WireEnum {
  drink('drink'),
  mainDish('main_dish'),
  snack('snack'),
  dessert('dessert');

  const FoodCategory(this.value);
  @override
  final String value;

  static List<String> get wireValues => values.map((e) => e.value).toList();
}

enum Confidence implements WireEnum {
  high('high'),
  low('low');

  const Confidence(this.value);
  @override
  final String value;
}

enum ChallengeType implements WireEnum {
  maxSugaryDrinks('max_sugary_drinks'),
  lessSugarOrders('less_sugar_orders'),
  vegMeals('veg_meals'),
  maxFriedMeals('max_fried_meals');

  const ChallengeType(this.value);
  @override
  final String value;

  /// Loại "tối đa": thành công khi tiến độ KHÔNG vượt mục tiêu.
  /// Loại "tối thiểu": thành công khi tiến độ ĐẠT mục tiêu.
  bool get isMaxType =>
      this == ChallengeType.maxSugaryDrinks || this == ChallengeType.maxFriedMeals;
}

enum ChallengeStatus implements WireEnum {
  active('active'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const ChallengeStatus(this.value);
  @override
  final String value;
}

enum AppThemeMode implements WireEnum {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemeMode(this.value);
  @override
  final String value;
}

/// Các thuộc tính được đánh giá theo mức độ.
///
/// [itemKey]: khóa trong `items[].levels` của meal (ví dụ "sugar").
/// [conditionKey]: khóa trong `applies_to` của tip và trong JSON của AI
/// (ví dụ "sugar_level").
enum LevelAttribute {
  sugar('sugar'),
  fat('fat'),
  carb('carb'),
  veg('veg'),
  protein('protein'),
  energy('energy');

  const LevelAttribute(this.itemKey);
  final String itemKey;

  String get conditionKey => '${itemKey}_level';

  /// Với rau và đạm, "nhiều" là tốt (màu hiển thị được đảo ngược).
  bool get higherIsBetter =>
      this == LevelAttribute.veg || this == LevelAttribute.protein;
}
