import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_config.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/tip.dart';
import '../../domain/enums.dart';
import '../../domain/repositories/meal_repository.dart';
import 'firestore_converters.dart';
import 'firestore_paths.dart';

/// Nhật ký ăn uống trên Firestore: `users/{uid}/meals/{mealId}`.
///
/// Xóa mềm (tombstone): xóa = đặt `is_deleted: true` + `deleted_at`.
/// Mọi truy vấn nhật ký/thống kê đều lọc `is_deleted == false`
/// (cần composite index is_deleted + eaten_at, xem firestore.indexes.json).
///
/// Các hàm ghi KHÔNG chờ server để vẫn dùng được khi mất mạng
/// (xem [FirestoreConverters.fireAndForget]).
class FirestoreMealRepository implements MealRepository {
  FirestoreMealRepository(this._paths);

  final FirestorePaths _paths;

  Query<Map<String, dynamic>> _active(String uid) =>
      _paths.meals(uid).where('is_deleted', isEqualTo: false);

  Query<Map<String, dynamic>> _between(String uid, DateTime startUtc, DateTime endUtc) {
    return _active(uid)
        .where('eaten_at', isGreaterThanOrEqualTo: FirestoreConverters.toTimestamp(startUtc))
        .where('eaten_at', isLessThan: FirestoreConverters.toTimestamp(endUtc))
        .orderBy('eaten_at', descending: true);
  }

  List<Meal> _toMeals(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map((d) => mealFromMap(d.id, d.data())).toList();

  @override
  Stream<List<Meal>> watchMealsBetween(String uid, DateTime startUtc, DateTime endUtc) =>
      _between(uid, startUtc, endUtc).snapshots().map(_toMeals);

  @override
  Future<List<Meal>> getMealsBetween(String uid, DateTime startUtc, DateTime endUtc) async =>
      _toMeals(await _between(uid, startUtc, endUtc).get());

  @override
  Stream<List<Meal>> watchRecentMeals(String uid, {int limit = 3}) => _active(uid)
      .orderBy('eaten_at', descending: true)
      .limit(limit)
      .snapshots()
      .map(_toMeals);

  @override
  Stream<List<Meal>> watchDeletedMeals(String uid) => _paths
      .meals(uid)
      .where('is_deleted', isEqualTo: true)
      .orderBy('deleted_at', descending: true)
      .snapshots()
      .map(_toMeals);

  @override
  String addMeal(String uid, Meal meal) {
    final ref = _paths.meals(uid).doc();
    final data = mealToMap(meal)
      ..['created_at'] = FieldValue.serverTimestamp()
      ..['updated_at'] = FieldValue.serverTimestamp();
    FirestoreConverters.fireAndForget(ref.set(data), 'addMeal');
    return ref.id;
  }

  @override
  void updateMeal(String uid, Meal meal) {
    final data = mealToMap(meal)..['updated_at'] = FieldValue.serverTimestamp();
    FirestoreConverters.fireAndForget(
      _paths.meals(uid).doc(meal.id).set(data, SetOptions(merge: true)),
      'updateMeal',
    );
  }

  @override
  void softDelete(String uid, String mealId) {
    FirestoreConverters.fireAndForget(
      _paths.meals(uid).doc(mealId).update({
        'is_deleted': true,
        // Dùng giờ máy (không dùng serverTimestamp) để Thùng rác sắp xếp
        // đúng ngay cả khi đang offline.
        'deleted_at': Timestamp.now(),
        'updated_at': FieldValue.serverTimestamp(),
      }),
      'softDelete',
    );
  }

  @override
  void restore(String uid, String mealId) {
    FirestoreConverters.fireAndForget(
      _paths.meals(uid).doc(mealId).update({
        'is_deleted': false,
        'deleted_at': null,
        'updated_at': FieldValue.serverTimestamp(),
      }),
      'restore',
    );
  }

  @override
  void deletePermanently(String uid, String mealId) {
    FirestoreConverters.fireAndForget(_paths.meals(uid).doc(mealId).delete(), 'deleteMeal');
  }

  // ---------------------------------------------------------------------------
  // Mapper Meal <-> Map (snake_case trong Firestore)
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> mealToMap(Meal meal) => {
        'eaten_at': FirestoreConverters.toTimestamp(meal.eatenAt),
        'meal_type': meal.mealType.value,
        'input_method': meal.inputMethod.value,
        'items': meal.items.map(_itemToMap).toList(),
        'user_edited': meal.userEdited,
        'is_deleted': meal.isDeleted,
        'deleted_at': meal.deletedAt == null
            ? null
            : FirestoreConverters.toTimestamp(meal.deletedAt!),
      };

  static Map<String, dynamic> _itemToMap(FoodItem item) => {
        'name': item.name,
        'category': item.category.value,
        'levels': FirestoreConverters.levelsToMap(item.levels),
        'short_note': item.shortNote,
        'confidence': item.confidence.value,
        // Lưu BẢN SAO nội dung gợi ý tại thời điểm ghi.
        'tips': item.tips
            .map((t) => {'code': t.code, 'title': t.title, 'content': t.content})
            .toList(),
      };

  static Meal mealFromMap(String id, Map<String, dynamic> m) {
    final rawItems = m['items'] is List ? m['items'] as List : const [];
    return Meal(
      id: id,
      eatenAt: FirestoreConverters.toDateTime(m['eaten_at']) ?? DateTime.now().toUtc(),
      mealType: parseWire(MealType.values, m['meal_type'], MealType.snack),
      inputMethod: parseWire(InputMethod.values, m['input_method'], InputMethod.manual),
      items: rawItems.whereType<Map>().map(_itemFromMap).toList(),
      userEdited: m['user_edited'] == true,
      isDeleted: m['is_deleted'] == true,
      deletedAt: FirestoreConverters.toDateTime(m['deleted_at']),
      createdAt: FirestoreConverters.toDateTime(m['created_at']),
      updatedAt: FirestoreConverters.toDateTime(m['updated_at']),
    );
  }

  static FoodItem _itemFromMap(Map m) {
    final rawTips = m['tips'] is List ? m['tips'] as List : const [];
    return FoodItem(
      name: (m['name'] as String?) ?? '',
      category: parseWire(FoodCategory.values, m['category'], FoodCategory.mainDish),
      levels: FirestoreConverters.levelsFromMap(m['levels']),
      shortNote: (m['short_note'] as String?) ?? '',
      confidence: parseWire(Confidence.values, m['confidence'], Confidence.high),
      tips: rawTips
          .whereType<Map>()
          .map((t) => TipSnapshot(
                code: (t['code'] as String?) ?? '',
                title: (t['title'] as String?) ?? '',
                content: (t['content'] as String?) ?? '',
              ))
          .take(AppConfig.maxTipsPerItem)
          .toList(),
    );
  }
}
