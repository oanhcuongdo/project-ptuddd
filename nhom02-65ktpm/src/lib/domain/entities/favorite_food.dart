import '../enums.dart';
import 'nutrition_levels.dart';

/// Món hay ăn `users/{uid}/favorites/{favId}`, phục vụ tính năng "Ăn lại".
class FavoriteFood {
  const FavoriteFood({
    required this.id,
    required this.name,
    required this.category,
    required this.levels,
    this.useCount = 0,
    this.lastUsedAt,
  });

  final String id;
  final String name;
  final FoodCategory category;
  final NutritionLevels levels;
  final int useCount;
  final DateTime? lastUsedAt;

  /// Tạo id ổn định từ tên + loại món để mỗi lần lưu cùng món sẽ cộng dồn
  /// `use_count` vào cùng một document thay vì tạo document mới.
  static String buildId(String name, FoodCategory category) {
    final normalized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll('/', '-');
    return 'f_${normalized}_${category.value}';
  }
}
