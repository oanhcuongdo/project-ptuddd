import '../entities/nutrition_levels.dart';
import '../entities/tip.dart';
import '../enums.dart';

/// Quy tắc chọn gợi ý theo mục tiêu + mức độ (Dart thuần, có unit test).
///
/// Điều kiện `applies_to` của tip: AND giữa các khóa, OR trong từng mảng.
/// Ví dụ `{category: [drink], sugar_level: [high, medium]}` nghĩa là
/// "đồ uống VÀ độ ngọt cao HOẶC vừa".
class TipSelector {
  TipSelector._();

  /// Tip có khớp với món (loại + mức độ) không.
  static bool matches(Tip tip, FoodCategory category, NutritionLevels levels) {
    for (final entry in tip.appliesTo.entries) {
      final allowed = entry.value;
      if (allowed.isEmpty) continue;
      final actual = _valueFor(entry.key, category, levels);
      // Khóa lạ -> coi như không khớp (an toàn hơn là gắn nhầm gợi ý).
      if (actual == null || !allowed.contains(actual)) return false;
    }
    return true;
  }

  static String? _valueFor(String key, FoodCategory category, NutritionLevels levels) {
    if (key == 'category') return category.value;
    for (final attribute in LevelAttribute.values) {
      if (attribute.conditionKey == key) return levels.of(attribute).value;
    }
    return null;
  }

  /// Các tip đang bật và phù hợp mục tiêu, ưu tiên cao trước.
  /// Dùng để đưa danh sách mã được phép vào prompt/schema của AI.
  static List<Tip> forGoal(Iterable<Tip> tips, Goal goal) {
    final result = tips.where((t) => t.active && t.goals.contains(goal)).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return result;
  }

  /// Chọn tối đa [max] tip theo quy tắc (không cần AI).
  static List<Tip> select({
    required Iterable<Tip> tips,
    required Goal goal,
    required FoodCategory category,
    required NutritionLevels levels,
    int max = 3,
  }) {
    return forGoal(tips, goal)
        .where((t) => matches(t, category, levels))
        .take(max)
        .toList();
  }

  /// Kết hợp mã AI chọn với thư viện:
  /// 1. Bỏ mã không tồn tại / đã tắt trong thư viện (phòng hờ AI "bịa" mã).
  /// 2. Nếu AI không chọn mã nào hợp lệ: bổ sung tối đa 1 tip theo quy tắc.
  /// 3. Tổng không quá [max] tip.
  static List<Tip> resolve({
    required List<String> aiCodes,
    required Map<String, Tip> library,
    required Goal goal,
    required FoodCategory category,
    required NutritionLevels levels,
    int max = 3,
  }) {
    final result = <Tip>[];
    for (final code in aiCodes) {
      final tip = library[code];
      if (tip != null && tip.active && !result.contains(tip)) result.add(tip);
    }
    if (result.isEmpty) {
      result.addAll(select(
        tips: library.values,
        goal: goal,
        category: category,
        levels: levels,
        max: 1,
      ));
    }
    return result.take(max).toList();
  }
}
