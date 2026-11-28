import '../enums.dart';
import 'food_item.dart';

/// Một bữa ăn trong nhật ký `users/{uid}/meals/{mealId}`.
///
/// Mọi mốc thời gian là UTC; chỉ đổi sang giờ Việt Nam khi hiển thị/tính tuần.
class Meal {
  const Meal({
    this.id,
    required this.eatenAt,
    required this.mealType,
    required this.inputMethod,
    required this.items,
    this.userEdited = false,
    this.isDeleted = false,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// null khi chưa lưu.
  final String? id;
  final DateTime eatenAt;
  final MealType mealType;
  final InputMethod inputMethod;
  final List<FoodItem> items;

  /// true nếu người dùng đã sửa bất kỳ trường nào so với kết quả AI.
  final bool userEdited;

  /// Xóa mềm (tombstone): bữa ăn vẫn còn trong Firestore để khôi phục.
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Meal copyWith({
    String? id,
    DateTime? eatenAt,
    MealType? mealType,
    InputMethod? inputMethod,
    List<FoodItem>? items,
    bool? userEdited,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Meal(
      id: id ?? this.id,
      eatenAt: eatenAt ?? this.eatenAt,
      mealType: mealType ?? this.mealType,
      inputMethod: inputMethod ?? this.inputMethod,
      items: items ?? this.items,
      userEdited: userEdited ?? this.userEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
