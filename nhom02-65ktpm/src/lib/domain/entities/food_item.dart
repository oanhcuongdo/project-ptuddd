import '../enums.dart';
import 'nutrition_levels.dart';
import 'tip.dart';

/// Một món trong bữa ăn.
class FoodItem {
  const FoodItem({
    required this.name,
    required this.category,
    required this.levels,
    this.shortNote = '',
    this.confidence = Confidence.high,
    this.tips = const [],
  });

  final String name;
  final FoodCategory category;
  final NutritionLevels levels;

  /// Câu mô tả ngắn do AI viết (chỉ mô tả món, không phải lời khuyên).
  final String shortNote;
  final Confidence confidence;

  /// Bản sao các gợi ý tại thời điểm ghi.
  final List<TipSnapshot> tips;

  FoodItem copyWith({
    String? name,
    FoodCategory? category,
    NutritionLevels? levels,
    String? shortNote,
    Confidence? confidence,
    List<TipSnapshot>? tips,
  }) {
    return FoodItem(
      name: name ?? this.name,
      category: category ?? this.category,
      levels: levels ?? this.levels,
      shortNote: shortNote ?? this.shortNote,
      confidence: confidence ?? this.confidence,
      tips: tips ?? this.tips,
    );
  }
}
