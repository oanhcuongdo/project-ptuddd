import 'package:flutter/foundation.dart';

import '../../../application/confirm_and_save_meal.dart';
import '../../../application/tip_resolver.dart';
import '../../../core/result.dart';
import '../../../core/strings/diary_strings.dart';
import '../../../domain/entities/food_item.dart';
import '../../../domain/entities/meal.dart';
import '../../../domain/entities/nutrition_levels.dart';
import '../../../domain/enums.dart';
import '../../../domain/rules/meal_type_rules.dart';

/// Một món đang được sửa trên màn hình xác nhận.
class EditableItem {
  EditableItem({
    required this.item,
    required this.fromAi,
    this.removable = false,
  }) : key = UniqueKey();

  final Key key;
  FoodItem item;
  bool selected = true;

  /// Người dùng đã sửa món này (so với kết quả AI).
  bool edited = false;
  final bool fromAi;

  /// Món do người dùng tự thêm: được phép bỏ hẳn khỏi danh sách.
  final bool removable;

  bool get needsReview => fromAi && item.confidence == Confidence.low;
}

/// Trạng thái màn hình Xác nhận bữa ăn (ChangeNotifier).
///
/// Chỉ ghi Firestore khi gọi [save] (người dùng nhấn Lưu).
/// Sửa bất kỳ trường nào của kết quả AI -> `user_edited = true`.
class ReviewController extends ChangeNotifier {
  ReviewController({
    required List<FoodItem> items,
    required this.inputMethod,
    required bool fromAi,
    required TipResolver tips,
    required ConfirmAndSaveMeal save,
    this.existingMeal,
    DateTime? initialEatenAt,
    MealType? initialMealType,
  })  : _tipResolver = tips,
        _saveMeal = save {
    eatenAt = existingMeal?.eatenAt ?? initialEatenAt ?? DateTime.now().toUtc();
    mealType = existingMeal?.mealType ?? initialMealType ?? MealTypeRules.defaultFor(eatenAt);
    _userEdited = existingMeal?.userEdited ?? false;
    entries = [
      for (final item in items) EditableItem(item: item, fromAi: fromAi),
    ];
    // Kết quả AI mới chưa lưu: hỏi lại trước khi thoát để không mất kết quả.
    dirty = existingMeal == null && fromAi && items.isNotEmpty;
  }

  final TipResolver _tipResolver;
  final ConfirmAndSaveMeal _saveMeal;
  final InputMethod inputMethod;
  final Meal? existingMeal;

  late DateTime eatenAt;
  late MealType mealType;
  late List<EditableItem> entries;
  late bool _userEdited;
  bool dirty = false;

  bool get isEditingExisting => existingMeal != null;

  void _changed({EditableItem? edited}) {
    if (edited != null) edited.edited = true;
    dirty = true;
    notifyListeners();
  }

  void setMealType(MealType type) {
    mealType = type;
    _changed();
  }

  void setEatenAt(DateTime instant) {
    final now = DateTime.now().toUtc();
    eatenAt = instant.isAfter(now) ? now : instant;
    _changed();
  }

  void toggleSelected(EditableItem entry, bool selected) {
    entry.selected = selected;
    _changed(edited: entry);
  }

  void rename(EditableItem entry, String name) {
    entry.item = entry.item.copyWith(name: name);
    _changed(edited: entry);
  }

  void setCategory(EditableItem entry, FoodCategory category) {
    entry.item = entry.item.copyWith(category: category);
    _refreshTips(entry);
    _changed(edited: entry);
  }

  void setLevel(EditableItem entry, LevelAttribute attribute, Level level) {
    entry.item = entry.item.copyWith(levels: entry.item.levels.withLevel(attribute, level));
    _refreshTips(entry);
    _changed(edited: entry);
  }

  /// Thêm một món trống để người dùng tự chọn mức độ bằng chip.
  void addBlankItem() {
    final entry = EditableItem(
      item: const FoodItem(name: '', category: FoodCategory.mainDish, levels: NutritionLevels()),
      fromAi: false,
      removable: true,
    );
    _refreshTips(entry);
    entries.add(entry);
    _changed();
  }

  void remove(EditableItem entry) {
    entries.remove(entry);
    _changed();
  }

  /// Tính lại gợi ý sau khi sửa: món AI giữ gợi ý còn khớp, món thủ công
  /// chọn lại theo quy tắc.
  void _refreshTips(EditableItem entry) {
    final tips = entry.fromAi
        ? _tipResolver.afterEdit(entry.item)
        : _tipResolver.forManualItem(entry.item);
    entry.item = entry.item.copyWith(tips: tips);
  }

  /// Gọi lại khi thư viện tips vừa tải xong (món thủ công chưa có gợi ý).
  void refreshManualTips() {
    for (final entry in entries) {
      if (!entry.fromAi && entry.item.tips.isEmpty) _refreshTips(entry);
    }
    notifyListeners();
  }

  Result<String> save() {
    final selected = entries.where((e) => e.selected).toList();
    if (selected.isEmpty) {
      return const Err(AppFailure(FailureType.invalidResponse, ReviewStrings.selectAtLeastOne));
    }
    if (selected.any((e) => e.item.name.trim().isEmpty)) {
      return const Err(AppFailure(FailureType.invalidResponse, ReviewStrings.nameRequired));
    }
    final userEdited = _userEdited ||
        entries.any((e) => e.fromAi && (e.edited || !e.selected));
    final result = _saveMeal(
      items: selected.map((e) => e.item).toList(),
      mealType: mealType,
      eatenAt: eatenAt,
      inputMethod: inputMethod,
      userEdited: userEdited,
      existingId: existingMeal?.id,
    );
    if (result.isOk) dirty = false;
    return result;
  }
}
